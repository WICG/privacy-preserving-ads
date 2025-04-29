# Copyright (c) Microsoft Corporation
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

from typing import List, Optional, BinaryIO

import argparse
import base64
import csv
import json
import logging
import os
import re
import shutil
import struct
import time

"""
USAGE EXAMPLE:
python3 index_builder.py -d 64 -k 50 -m 50 -t int8 -i csv_example.csv

This script is used to build an index for the KVS ANN hook.
To run it you should call this .py file with python3 program and provide all required parameters.
For parameters and usage, run the script with the --help flag, check parse_args() function or check documentation.
IMPORTANT: The script only builds an index if you already generated embeddings on your end. Embedding types supported:
float[N], int8[N], uint8[N] where N - positive integer.

The script reads a CSV file with two columns: the first column is a Base64 encoded embedding,
and the second column is a JSON payload for this embedding - it could be anything,
this is what you will get as a selection result in UDF after call getNearestNeighbors.

Output is a snapshot file with the index and metadata called ANNSNAPSHOT_<epoch>,
where <epoch> is the current timestamp by default.
The snapshot file is used by the KVS ANN hook to load the index.
IMPORTANT: To replace current index, new snapshot file name must match the pattern ^ANNSNAPSHOT_\d{16}$,
and also epoch should be greater than the previous one, otherwise it will be ignored.

To successfully run the script, the DiskANN public repo must be cloned and built
(it will happen automatically if you have git and cmake installed).
The script uses the build_memory_index program from the DiskANN repo to build an index.
The snapshot file is created in the current working directory by default.
"""

# Set up logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)

GLOBAL_INDEX_WORKFOLDER = "/tmp/index_workfolder"
GLOBAL_PREBUILD_FILENAME = f"{GLOBAL_INDEX_WORKFOLDER}/index_prebuild_file"
GLOBAL_OUTPUT_FOLDER = f"{GLOBAL_INDEX_WORKFOLDER}/index_folder"
GLOBAL_MAPPING_FILENAME = f"{GLOBAL_OUTPUT_FOLDER}/mapping"
GLOBAL_CONFIG_JSON_FILENAME = f"{GLOBAL_OUTPUT_FOLDER}/config.json"
GLOBAL_INDEX_FILENAME = f"{GLOBAL_OUTPUT_FOLDER}/index"
GLOBAL_INDEX_DATA_FILENAME = f"{GLOBAL_INDEX_FILENAME}.data"
GLOBAL_DISKANN_REPO_PATH = "/tmp/DiskANN"
GLOBAL_BUILD_INDEX_PROGRAM = f"{GLOBAL_DISKANN_REPO_PATH}/build/apps/build_memory_index"


def read_csv(csv_filename: str) -> List[List[str]]:
    """
    Reads a CSV file and returns the data as a list of rows.

    :param csv_filename: The path to the CSV file.
    :return: A list of rows, where each row is a list of strings.
    """
    try:
        with open(csv_filename, mode="r", encoding="utf-8") as rfile:
            csv_reader = csv.reader(rfile, delimiter="\t")

            data = [row for row in csv_reader]
            logging.info(f"Successfully read {len(data)} rows from {csv_filename}.")
            return data
    except FileNotFoundError as e:
        logging.error(f"File not found: {csv_filename}")
        raise e

    except Exception as e:
        logging.error(f"Error reading {csv_filename}: {str(e)}")
        raise e


def decode_base64(encoded_str: str) -> Optional[bytes]:
    """
    Decodes a Base64 encoded string.

    :param encoded_str: The Base64 encoded string.
    :return: The decoded bytes, or None if decoding fails.
    """
    try:
        decoded_bytes = base64.b64decode(encoded_str)
        return decoded_bytes
    except base64.binascii.Error as e:
        logging.error(f"Base64 decoding error: {str(e)}")
        return None


def write_json_payload_to_file(mapping_file: BinaryIO, json_payload: str) -> None:
    """
    Write a JSON payload to a file.
    Destination - mapping file for index builder
    Specific format is required by the KV mapping reader.

    :param mapping_file: Binary file to write to.
    :param json_payload: what to write.
    :return: None.
    """
    # Convert the string to bytes (the bytes representation of the string)
    encoded_string = json_payload.encode("utf-8")
    str_len = convert_to_le_int32(len(encoded_string))
    # Write the length of the string (uint32)
    mapping_file.write(str_len)
    # Write the string data (raw bytes)
    mapping_file.write(encoded_string)


def write_embedding_to_file(embedding_file: BinaryIO, embedding: bytes) -> None:
    """
    Write an embedding to - the raw bytes.
    Destination - data file for index builder.
    Specific format is required by the index builder.

    :param mapping_file: Binary file to write to.
    :param embedding: fixed-size binary data to write.
    :return: None.
    """
    # all embeddings are the same size
    embedding_file.write(embedding)


def convert_to_le_int32(input_integer: int) -> bytes:
    """
    Convert the integer to a 4-byte binary format (little-endian)

    :param input_integer: integer to convert.
    :return: bytes[4] object with little ending binary representation.
    """
    binary_data = struct.pack("<I", input_integer)
    return binary_data


def prepare_index_data_and_mapping(args: object) -> None:
    """
    Processes a CSV file, preparing the data for indexing.
    Also, preparing mapping file.

    :param args: command line parsed arguments.
    :return: None.
    """
    data = read_csv(args.input_csv)
    embeddings_count = convert_to_le_int32(len(data))

    expected_embedding_size = args.dimension
    if args.vec_type == "float":
        expected_embedding_size *= 4

    try:
        # in perfect world we would have a "with" section, but we have 2 files to write
        embedding_file = open(GLOBAL_PREBUILD_FILENAME, "wb")
        mapping_file = open(GLOBAL_MAPPING_FILENAME, "wb")

        mapping_file.write(embeddings_count)
        embedding_file.write(embeddings_count)
        embedding_file.write(convert_to_le_int32(args.dimension))
        for line in data:
            if len(line) != 2:
                error_msg = f"Invalid CSV line due to incorrect format: {line}, expected 2 columns"
                logging.error(error_msg)
                raise ValueError(error_msg)
            based_embedding, json_payload = line

            embedding = decode_base64(based_embedding)
            if json_payload and embedding:
                if len(embedding) != expected_embedding_size:
                    error_msg = f"Incorrect embedding in line {line}"
                    logging.error(error_msg)
                    raise ValueError(error_msg)
                # writing to both files
                write_embedding_to_file(embedding_file, embedding)
                write_json_payload_to_file(mapping_file, json_payload)
            else:
                error_msg = f"Incorrect line: {line}"
                logging.error(error_msg)
                raise ValueError(error_msg)
        embedding_file.close()
        mapping_file.close()
    except IOError as e:
        logging.error(f"Failed processing of {args.input_csv}: {str(e)}")
        raise e


def create_workfolder():
    """
    Prepare workfolder for index builder.

    :return: None.
    """
    shutil.rmtree(GLOBAL_INDEX_WORKFOLDER, ignore_errors=True)
    os.mkdir(GLOBAL_INDEX_WORKFOLDER)
    os.mkdir(GLOBAL_OUTPUT_FOLDER)


def create_build_index_program():
    """
    Prepare build_memory_index program from DiskANN public repo.
    installed git and cmake are required.

    :return: None.
    """
    if os.path.exists(GLOBAL_DISKANN_REPO_PATH):
        pass
    else:
        os.system(
            f"cd {GLOBAL_DISKANN_REPO_PATH}/..;"
            "git clone https://github.com/microsoft/DiskANN.git"
        )
    if os.path.exists(GLOBAL_BUILD_INDEX_PROGRAM):
        pass
    else:
        os.mkdir(f"{GLOBAL_DISKANN_REPO_PATH}/build")
        os.system(
            f"cd {GLOBAL_DISKANN_REPO_PATH}/build;"
            "cmake -DCMAKE_BUILD_TYPE=Release ..;"
            "make -j"
        )


def build_index(args: object) -> None:
    """
    Build index using DiskANN build_memory_index program.
    Requires DiskANN public repo prepared.
    Requires prebuild data file.

    :param args: command line parsed arguments.
    :return: None.
    """
    os.system(
        f"{GLOBAL_BUILD_INDEX_PROGRAM}"
        f" --data_type {args.vec_type}"
        f" --dist_fn {args.distance_function}"
        f" --data_path {GLOBAL_PREBUILD_FILENAME}"
        f" --index_path_prefix {GLOBAL_INDEX_FILENAME}"
        f" -R {args.graph_degree}"
        f" -L {args.leaf_size}"
        f" --alpha {args.graph_diameter}"
    )
    if not os.path.exists(GLOBAL_INDEX_FILENAME):
        error_msg = "Index build failed"
        logging.error(error_msg)
        raise ValueError(error_msg)
    if not os.path.exists(GLOBAL_INDEX_DATA_FILENAME):
        error_msg = "Index build failed"
        logging.error(error_msg)
        raise ValueError(error_msg)


def dump_config_json(args: object) -> None:
    """
    Dump config.json file with all parameters used for index build.
    Required for snapshot generation.

    :param args: command line parsed arguments.
    :return: None.
    """
    with open(GLOBAL_CONFIG_JSON_FILENAME, "w") as wfile:
        config_dictionary = {}
        config_dictionary["Dimension"] = args.dimension
        config_dictionary["QueryNeighborsCount"] = args.max_search
        config_dictionary["TopCount"] = args.top_count
        config_dictionary["VectorTypeStr"] = args.vec_type
        wfile.write(json.dumps(config_dictionary))


def pack_everything(args: object) -> None:
    """
    Pack all files into one snapshot file.
    Prepared index snapshot should have specific format.
    Prepared index snapshot name should match "^ANNSNAPSHOT_\\d{16}$".
    Prepared index snapshot should be after uploaded to Azure.

    :param args: command line parsed arguments.
    :return: None.
    """
    filenames = os.listdir(GLOBAL_OUTPUT_FOLDER)
    # sanity check
    if set(["index", "index.data", "mapping", "config.json"]) - set(filenames):
        logging.error("Script failed - some of files missing!")
        raise ValueError
    with open(args.output, "wb") as wfile:
        wfile.write(convert_to_le_int32(0xF00DFEED))
        wfile.write(convert_to_le_int32(len(filenames)))
        for filename in filenames:
            wfile.write(convert_to_le_int32(len(filename)))
            wfile.write(bytes(filename, encoding="utf8"))
            with open(f"{GLOBAL_OUTPUT_FOLDER}/{filename}", "rb") as rfile:
                content = rfile.read()
            wfile.write(struct.pack("<Q", len(content)))
            wfile.write(content)


def parse_args() -> object:
    """
    Parse command line arguments.

    :return: object with parsed arguments.
    """
    # Set up argument parser
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--dimension",
        "-D",
        "-d",
        type=int,
        required=True,
        help="The integer dimension of each embedding.",
    )
    parser.add_argument(
        "--top_count",
        "-K",
        "-k",
        "-N",
        "-n",
        type=int,
        required=True,
        help=(
            "Number of search results for each query."
            " Example - for 10 will be top 10 results"
            " for each embedding."
        ),
    )
    parser.add_argument(
        "--max_search",
        "-M",
        "-m",
        type=int,
        required=True,
        help=(
            "Number of results required to stop searching."
            " Example - for 100 as max_search and"
            " 10 as top_result each search will return"
            " 10 results, but internally it will search"
            " for 100 results first"
            " and then return top 10 from those 100."
        ),
    )
    parser.add_argument(
        "--vec_type",
        "-T",
        "-t",
        type=str,
        required=True,
        help="The type of each embedding coordinate.",
        choices=["float", "int8", "uint8"],
    )
    parser.add_argument(
        "--distance_function",
        "-F",
        "-f",
        type=str,
        required=False,
        default="l2",
        help=(
            "Distance function to use for search."
            " Currently only l2 (Euclidean distance) is supported."
        ),
        choices=["l2"],
    )
    parser.add_argument(
        "--graph_degree",
        "-R",
        "-r",
        type=int,
        required=False,
        default=64,
        help=(
            "Use only when you want to optimize the search quality."
            " Degree of graph index, optional. Larger values result larger"
            " index size and longer indexing time. but better search quality."
            " Default value is 64. Allowed values are between 32 and 150."
        ),
    )
    parser.add_argument(
        "--leaf_size",
        "-L",
        "-l",
        type=int,
        required=False,
        default=100,
        help=(
            "Use only when you want to optimize the search quality."
            " Size of search list we maintain during index building."
            " Larger values will take more time to build but result in indices"
            " that provide higher recall for the same search complexity."
            " Typical values are between 75 to 400, default is 100."
        ),
    )
    parser.add_argument(
        "--graph_diameter",
        "--alpha",
        "-A",
        "-a",
        type=float,
        required=False,
        default=1.2,
        help=(
            "Use only when you want to optimize the search quality."
            " This value determines the diameter of the graph,"
            " which will be approximately log n to the base alpha."
            " Optional float value between 1.0 and 1.5, default is 1.2."
            " 1 will yield the sparsest graph, 1.5 will yield denser graphs."
        ),
    )
    parser.add_argument(
        "--input_csv",
        "-I",
        "-i",
        type=str,
        required=True,
        help="The name of the file to process.",
    )
    parser.add_argument(
        "--output",
        "-O",
        "-o",
        type=str,
        required=False,
        help=("The name of the output file. Remember to use the correct format."),
    )
    parser.add_argument(
        "--epoch",
        "-E",
        "-e",
        type=int,
        required=False,
        default=int(time.time()),
        help=(
            "Epoch of the output file. Remember to use the correct format."
            " Not used in case if specific output file is provided."
            " Default value is current timespamp."
        ),
    )
    # Parse arguments
    retval = parser.parse_args()
    if not retval.output:
        retval.output = f"ANNSNAPSHOT_{retval.epoch:016d}"
    else:
        if not re.match(r"^ANNSNAPSHOT_\d{16}$", retval.output.split("/")[-1]):
            error_msg = "Output filename should match with ^ANNSNAPSHOT_\d{16}$"
            logging.error(error_msg)
            raise ValueError(error_msg)
    return retval


def Main() -> None:
    """
    Main function to run the script.

    :return: None.
    """
    args = parse_args()
    logging.info("Args parsed.")

    create_workfolder()
    logging.info("Work folder prepared.")

    prepare_index_data_and_mapping(args)
    logging.info("Data for index builder prepared.")
    logging.info("Mapping file created.")

    create_build_index_program()
    logging.info("DiskANN build_memory_index program ready.")

    build_index(args)
    logging.info("Index build successful.")

    dump_config_json(args)
    logging.info("config.json created.")

    pack_everything(args)
    logging.info(f"New snapshot {args.output} generated successfully.")

    logging.info("Removing intermediate files.")
    shutil.rmtree(GLOBAL_INDEX_WORKFOLDER)

    logging.info("Done.")


if __name__ == "__main__":
    Main()
