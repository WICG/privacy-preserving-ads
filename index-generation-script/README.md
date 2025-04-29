Below is comprehensive documentation for the provided script. It covers:

1. **Overview and Purpose**
2. **Requirements**
3. **Usage**
4. **CSV File Format**
5. **Index-Building Steps**
6. **ANNSNAPSHOT File Format**
7. **config.json**
8. **Replacing/Updating the Index**
9. **Script Internals Overview**
10. **Example Command**

---

## 1. Overview and Purpose

This script builds an Approximate Nearest Neighbor (ANN) index using
[DiskANN](https://github.com/microsoft/DiskANN). It produces a self-contained "snapshot" file named
`ANNSNAPSHOT_<epoch>` that can be loaded by a KVS and used by ANN getNearestNeighbors hook. The
workflow of this tool:

1. Read in a CSV file of embeddings plus JSON payloads.
2. Convert these into a form suitable for building an ANN index (i.e., generating a data file) +
   generates a mapping file.
3. Use the `build_memory_index` utility from DiskANN repo to build the index.
4. Package the resulting index + configuration + mapping into a single snapshot file.

When the index snapshot is subsequently uploaded to the correct location (depending on how your KVS
is configured), a query to the ANN hook can retrieve nearest neighbors along with their JSON
payloads.

---

## 2. Requirements

-   **Python 3** (the script is written in Python 3).
-   **Git, cmake, and a C++ build toolchain** (to clone and build the DiskANN repository
    automatically).
-   **Write access** to create a temporary working folder `/tmp/index_workfolder` (this script will
    delete and recreate it) and to clone DiskANN repo to `/tmp` as well.

---

## 3. Usage

You can run the script via:

```bash
python3 index_builder.py [OPTIONS]
```

The key command-line arguments are:

-   `--dimension/ -d` (integer, **required**): The dimension of each embedding (e.g., 64).
-   `--top_count / -k` (integer, **required**): The top `K` results to retrieve for each query in an
    ANN search.
-   `--max_search / -m` (integer, **required**): An internal parameter controlling how many
    neighbors the ANN engine visits before finalizing the top `K`.
-   `--vec_type / -t` (`float`, `int8`, or `uint8`, **required**): The type of the embedding values.
-   `--input_csv / -i` (string, **required**): Path to the input CSV file.
-   `--output / -o` (string, optional): Desired name of the output snapshot file. Can be a path.
    Filename must match `^ANNSNAPSHOT_\d{16}$`. If not provided, a default of `ANNSNAPSHOT_{epoch}`
    is used.
-   `--epoch / -e` (integer, optional): Epoch/time to embed in the output filename if `--output` is
    not given (default is current UNIX timestamp).
-   **Advanced index build options** (all optional):
    -   Currently only `l2` (euclidean distance) is supported.
    -   `--graph_degree / -r`: "Degree" of the DiskANN graph; affects index size and performance
        (default 64).
    -   `--leaf_size / -l`: Size of the search list maintained during index building (default 100).
    -   `--graph_diameter / -a`: "Alpha" parameter controlling approximate diameter of the graph.
        Typical range is 1.0 to 1.5 (default 1.2).

To view full usage details with short flags, run:

```bash
python3 index_builder.py --help
```

PS: this script is abstraction above `build_memory_index` utility from `microsoft.DiskANN`, so you
can see similar options here:
[Usage for in-memory indices](https://github.com/microsoft/DiskANN/blob/main/workflows/in_memory_index.md).

---

## 4. CSV File Format

This script assumes your input CSV file has **exactly 2 columns**, separated by **tab** (`\t`). Each
row in the CSV represents:

1. **Base64-encoded embedding**
2. **JSON payload** (as a raw string) (**IMPORTANT** please do not use tabulation `\t` inside json,
   script can fail!) (PS: it can be anything, not exactly json.)

In other words, each row must look like:

```csv
<base64_embedding>    <json_payload>
```

(without quotes, and separated by a tab).

**Example row** (schematic):

```csv
AAECAwQFBgc=    {"id":12345,"foo":"bar","extra":42}
```

-   `<base64_embedding>` must decode to exactly `dimension * size_of_type` bytes.

    -   If `--vec_type float` and `dimension=64`, then each row's embedding must decode to
        `64 * 4 = 256 bytes`.
    -   If `--vec_type int8` and `dimension=64`, then each row's embedding must decode to `64`
        bytes.
    -   If `--vec_type uint8` and `dimension=64`, also `64` bytes, etc.

-   `<json_payload>`: The script does not parse this JSON content. It is treated as an opaque
    string. This JSON is what the ANN hook returns as the "payload" for the neighbor, you should
    handle it in UDF.

If any line fails these conditions, the script raises an error.

---

## 5. Index-Building Steps

Below is a high-level summary of how the script transforms your CSV into the final index snapshot:

1. **Create a temporary work folder**: `/tmp/index_workfolder`.
2. **Read the CSV**: The script reads all lines, expecting 2 tab-separated columns.
3. **Decode the embeddings**:
    - The Base64 strings in column 1 are decoded into binary.
    - The script verifies that each decoded embedding is the correct size.
4. **Write two critical files**:
    1. A "prebuild" embedding file (`index_prebuild_file`), containing the raw embeddings.
    2. A "mapping" file (`mapping`), containing the JSON payloads.
5. **Clone and build DiskANN** (if not already present and built) to obtain the `build_memory_index`
   binary.
6. **Run** `build_memory_index` with "prebuild" embedding file (`index_prebuild_file`) to produce
   the index files:
    - `index`
    - `index.data`
7. **Write a** `config.json` describing parameters (dimension, top_count, vector type, etc.) so that
   the consumer can interpret the index.
8. **Assemble a single** `ANNSNAPSHOT_<epoch>` file containing everything needed (index, mapping,
   config) in a consistent format.
9. **Clean up** temporary files.

---

## 6. ANNSNAPSHOT File Format

The script combines the index, mapping, and config into a single file for easy deployment. It names
this file either `ANNSNAPSHOT_<epoch>` or a user-provided filename that must match the pattern
`^ANNSNAPSHOT_\d{16}$`. Inside that file, the contents have the following structure (in
**little-endian** binary order):

1. **Magic number** (`0xF00DFEED`) stored as a 32-bit unsigned integer. This identifies the file as
   a snapshot.
2. **Number of files** (an unsigned 32-bit integer). Let's call it `N`.
3. For each of these `N` files:
    1. **Filename length** (an unsigned 32-bit integer), i.e. length of `filename` string in bytes.
    2. **Filename** (ASCII-encoded, exactly `filename_length` bytes).
    3. **File content length** (an unsigned 64-bit integer).
    4. **File content** (exactly `file_content_length` bytes).

The script includes exactly 4 files inside the snapshot:

-   `index`
-   `index.data`
-   `mapping`
-   `config.json`

Where:

-   `index / index.data`: The built ANN index from DiskANN.
-   `mapping`: Maps each index entry to the JSON payload from the CSV.
-   `config.json`: Contains basic configuration about dimension, vector type, etc.

Because the consumer (the KVS ANN hook) is aware of how to interpret these items, the snapshot is
entirely self-contained.

---

## 7. config.json

Internal file for ANNSNAPSHOT. Contains next options from this script:

-   `Dimension` - same as `-d` parameter
-   `QueryNeighborsCount` - same as `-m` parameter
-   `TopCount` - same as `-k` parameter
-   `VectorTypeStr` - same as `-t` parameter

---

## 8. Replacing/Updating the Index

To replace or update an existing index with a new snapshot:

1. **Ensure the new snapshot's filename** is `ANNSNAPSHOT_<newer_epoch>`, where `<newer_epoch>` is a
   16-digit integer **greater** than any snapshot previously deployed. (The KVS typically uses a
   simple rule: it only loads snapshots whose epoch is newer than what it has already seen.)
2. **Upload/place** that new snapshot in the directory or location the KVS expects.
3. The KVS will detect the presence of `ANNSNAPSHOT_<newer_epoch>` and begin using it if the epoch
   is valid.

**Important**: If the epoch is not strictly greater, the new snapshot will be ignored.

---

## 9. Script Internals Overview

Below are the main functions in the script, in approximate order of execution:

1. `parse_args()`: Parses the command-line arguments.
2. `Main()`: Orchestrates the flow.
3. `create_workfolder()`: Creates a fresh temporary working directory.
4. `prepare_index_data_and_mapping(args)`:
    - Reads rows from CSV.
    - Decodes embeddings and writes them to `index_prebuild_file`.
    - Writes JSON payloads to the `mapping` file.
5. `create_build_index_program()`: Clones and builds DiskANN if needed.
6. `build_index(args)`: Calls DiskANN's `build_memory_index` on the prepared data.
7. `dump_config_json(args)`: Writes the `config.json`.
8. `pack_everything(args)`: Packs `index`, `index.data`, `mapping`, and `config.json` into the final
   `ANNSNAPSHOT_<epoch>` file.
9. Cleans up the work folder.

---

## 10. Example Command

Below is a minimal example command:

```bash
python3 index_builder.py \
    --dimension 64 \
    --top_count 50 \
    --max_search 50 \
    --vec_type int8 \
    --input_csv csv_example.csv
```

-   **Dimension**: `64`
-   **Top count** (neighbors): `50`
-   **Max search**: `50`
-   **Vector type**: `int8`
-   **Input CSV**: `csv_example.csv`

This produces (by default) a file named `ANNSNAPSHOT_{CURRENT_EPOCH}`, for example
`ANNSNAPSHOT_0000001679598914` (with 16 digits). You can also specify:

```bash
python3 index_builder.py \
    -d 64 -k 50 -m 50 -t int8 \
    -i csv_example.csv \
    -o ANNSNAPSHOT_0000000000123456
```

to explicitly name the output file `ANNSNAPSHOT_0000000000123456`.

---

## Final Notes

1. **Memory Usage**: For large embeddings, building the index in memory can be sizable. Ensure your
   environment can handle it.
2. **Search Quality**: The `graph_degree`, `leaf_size`, and `graph_diameter` parameters can be tuned
   for better performance or recall. Larger values generally mean higher recall and more
   compute/memory usage.
3. **Distance Function**: Currently only L2 is supported by the script.

This completes the documentation for the script, the CSV input format, and the `ANNSNAPSHOT` output
format.
