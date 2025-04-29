# Technical Details
## 1.1 Introduction
The Key-Value Store (KVS) runs inside a **Trusted Execution Environment (TEE)** and supports limited read/write operations via JavaScript-based User-Defined Functions (UDFs). These UDFs execute in the **ROMA** sandbox, ensuring isolation. Whenever a UDF calls a hook function (like `getValues`), it transitions to native C++ code to perform the actual operation on the underlying storage.

A new hook function, `getNearestNeighbors`, has been introduced to facilitate approximate nearest-neighbor (ANN) lookups on vector embeddings.

## 1.2 Architectural Flow
### 1. UDF Execution in ROMA
* The JavaScript UDF is loaded into ROMA.
* The UDF receives requests (for example, a set of embeddings to process).
* When it needs to retrieve approximate neighbors, it calls `getNearestNeighbors(embeddings)`.

### 2. Hook Invocation
 The call transitions out of ROMA to the C++ layer. All C++ code is executed outside of any sandbox, so all ANN searches are performed effectively.

### 3. ANNIndex and Snapshots
* `ANNIndex` references an `ANNSnapshotKeeper`, which holds a `deque<ANNSnapshot>`.
* Only the latest snapshot in that deque is used for lookups.
* Each `ANNSnapshot` has:
  * Config: operational parameters (e.g., graph properties).
  * Abstract Index (`diskann::abstract_index`): the in-memory structure from [microsoft.DiskANN](https://github.com/microsoft/DiskANN) (note: link just for reference; actual usage is internal).
  * Mapping: a map from the internal vector ID to the actual embedding payload.

### 4. Performing the Search
* The last snapshot is used to find approximate neighbors for each embedding.
* The ANN search returns vector IDs, which the `mapping` then resolves back to real embedding keys or additional payload.

## 1.3 Snapshot Lifecycle
### 1. Naming and Validation
* Each snapshot must follow the naming pattern `ANNSNAPSHOT_<suffix>`, where suffix is 16-digit number, usually a timestamp. Example – ANNSNAPSHOT_0000001744588409
* `ANNIndex::TryAddANNSnapshot` checks whether the new snapshot is valid and has a timestamp more recent than the existing snapshot. If it is not fresh or is invalid, the new snapshot is rejected.

### 2. Files Inside the Snapshot Container
* `index` and `index.data`: used by DiskANN to store the index graph.
* `config.json`: parameters for the ANN index (dimensions, vector types, etc.). Currently, there are only 4 parameters:
  * vector type – primitive embedding element, single dimension. Could be signed or unsigned 1-byte integer or signed 4-byte float
  * dimension – how many elements of vector type are in each embedding. Example - 32
  * top count – how many results index will produce for a single query. Example - 50
  * query neighbors count – how many results should be found before taking top count as result. Higher value causes more precise search, but bigger latency. Should be not less than top count parameter. Example - 100
* `mapping`: bridging from the ANN internal IDs to the actual payloads.

### 3. Where Snapshots Are Stored
* Snapshots must be copied to the delta directory specified by `AZURE_LOCAL_DATA_DIR` (`delta_directory`) (e.g., `/data/deltas`).
* This is the same directory that also expects files like `DELTA_\d{16}`, which are used to deploy new UDFs or other KVS patches.

## 1.4 Embeddings and Data Types
* Embeddings must be generated externally by the user.
* Three supported element types for each embedding array:
  * `float`
  * `int8`
  * `uint8`
* The dimension (number of elements) is determined by the snapshot’s requirements. All embeddings in a single snapshot must have the same type and dimension.

**Important**: The user is responsible for ensuring consistency in dimension and data type when calling getNearestNeighbors.

## 1.5 index_builder.py (Creating Your Own Snapshot)
A Python script, `index_builder.py`, is provided to generate new snapshot files. It has it's own documentation `tools/microsoft_index_builder/README.md` in KVS repo. This tool is also duplicated in this repo, [index_builder.py](index-generation-script/index_builder.py) and [documentation](index-generation-script/README.md) To use it, you need:
 1. Prepare csv input with embeddings and values for each embedding
 2. Run `index_builder.py` with desired parameters
 3. Find `ANNSNAPSHOT_<timestamp>` (16-digit timestamp) in this folder.
 4. Copy it to the appropriate delta directory mounted for the KVS.
 5. Verification: KVS picks up the new snapshot if it is valid and more recent than the existing snapshot. You can check counters to understand is it successful or not.

## 1.6 Using the Same KVS for Key-Value Data and ANN
Because the KVS can store arbitrary keys and data, there is no built-in mechanism to distinguish normal keys from embedding keys. A recommended practice is:
* **Prefix** embedding keys with something like "ANN_EMBEDDING_".
* In your UDF logic, look for that prefix. If present, strip it and pass the remainder to getNearestNeighbors.

This avoids confusion between normal KVS keys and ANN embedding keys.

## 1.7 Counters
There are 7 of them:
* **AnnActiveSnapshotCount** - how many snapshots are in memory right now
* **AnnSnapshotLoadSuccessCount** - increasing every time when new ann snapshot successfully loaded
* **AnnSnapshotLoadErrorCount** - increasing every time when new ann snapshot not loaded because it's invalid
* **AnnSnapshotLoadExpiredCount** - increasing if there was a try to add snapshot with name timestamp less then current one (important - this counter can not be increased in some cases)
* **AnnHookTotalKeysCallCount** (noised) - Total number of keys goes to getNearestNeighbors hook calls
* **AnnHookErrorsCallCount** (noised) - Total number of keys goes to getNearestNeighbors hook calls which returns no result. In case if there are no active snapshots, all keys will be marked as errors; also, this usually happens when ANN expects embeddings with (as example) `16` bytes, but other embedding length was given.
* **AnnGetKeyValueSetLatencyInMicros** (noised) - latency of hook call









# Product Feature
Below is a more user-facing guide for those who just need to enable approximate nearest neighbor lookups in their existing TEE-based Key-Value Store.

## 2.1 Why Use getNearestNeighbors?
* Approximate Nearest Neighbors allows you to quickly find similar or “close” embeddings in high-dimensional spaces.
* Perfect for ad selection real-time queries.

## 2.2 Basic Steps to Enable ANN in Your TEE KVS
### 1. Embeddings – are lists/vectors of numbers, type of numbers are fixed for specific index and number of elements are also fixed and called dimension. Example of an embedding - [173, 217, 8, 93], this embedding has type of elements uint8 and dimension 4. You should generate embeddings:
* Obtain or generate embeddings from your domain-specific model.
* All embeddings must share the same dimension. Supported data types are:
  1. `float`
  2. `int8`
  3. `uint8`

### 2. Create an ANN Snapshot:
* Use `index_builder.py` to build a snapshot container containing:
* Ensure the container name follows the pattern ANNSNAPSHOT_\d{16}, where \d{16} is a unique 16-digit timestamp.

### 3. Upload the Snapshot:
* Copy your newly created folder or container to the same location where your KVS expects updates, e.g. a path like `/data/deltas`.
* Make sure name of new snapshot is greater than previous one
* **important**: during usage, KVS unpacks ANNSNAPSHOT locally and using aprx. same storage

### 4. Validate:
* The KVS automatically loads the latest valid snapshot at runtime.
* Check logs (or relevant monitoring) to ensure the snapshot was accepted. Also check counters **AnnSnapshotLoadSuccessCount** and **AnnSnapshotLoadErrorCount**

### 5. Call getNearestNeighbors from your UDF:
* In your KVS JavaScript UDF, prepare the code to work with embeddings and hook call results.
* Pass list of embeddings as list of strings into getNearestNeighbors().
* The system returns data structure containing nearest neighbor results.
* Usage examples can be found in tests (Key Value Service repo)
* Sample UDFs can be found in `/tools/udf/sample_udf` folder - `microsoft_udf_with_get_nns.js` for `getNearestNeighbors` hook and `udf.js` that supports both KV and ANN (Key Value Service repo). Content of `microsoft_udf_with_get_nns.js` shown in this document, section 2.3
* Upload you UDF usual way (through `/tools/udf/udf_generator` in Key Value Service repo and uploading it to the same folder as `DELTA_\d{16}` file)

### 6. Call KVS from bidding
 ```const fetchAdditionalSignalsResult = fetchAdditionalSignals(jsonRequest);```, where jsonRequest having request to ```SELECTION_KV_SERVER```




## 2.3 Example UDF Pseudocode
```javascript

function HandleRequest(executionMetadata, ...input) {
  let keyGroupOutputs = [];
  for (let argument of input) {
    let keyGroupOutput = {};
    keyGroupOutput.tags = argument.tags;
    let data = argument.hasOwnProperty('tags') ? argument.data : argument;
    const getNearestNeighborsResult = JSON.parse(getNearestNeighbors(data));
    // getNearestNeighborsResult returns "kvPairs" when successful and "code" on failure.
    // Ignore failures and only add successful getNearestNeighborsResult lookups to output.
    if (getNearestNeighborsResult.hasOwnProperty('kvPairs')) {
      const kvPairs = getNearestNeighborsResult.kvPairs;
      const keyValuesOutput = {};
      for (const key in kvPairs) {
        if (kvPairs[key].hasOwnProperty('keysetValues')) {
          // kvPairs[key].keysetValues.values is an array of neighbor embeddings for each key embedding.
          // values inside sorted by proximity to the key embedding.
          // The number of values returned is determined by index itself.
          keyValuesOutput[key] = { value: kvPairs[key].keysetValues.values };
        } else {
          keyValuesOutput[key] = { status: kvPairs[key].status };
        }
      }
      keyGroupOutput.keyValues = keyValuesOutput;
      keyGroupOutputs.push(keyGroupOutput);
    }
  }
  return { keyGroupOutputs, udfOutputApiVersion: 1 };
}
```

## 2.4 Best Practices
* Always use embeddings of the same dimension within a single snapshot. It is required.
* Versioning: Keep track of snapshot timestamps (e.g., 2025032514000000). If you upload an older snapshot, it will not replace a newer one.
* Performance Tuning: Adjust your DiskANN config parameters (see `/tools/microsoft_index_builder/README.md` for details) to balance speed vs. recall.
* Naming Convention: For clarity, prefix your ANN-related keys to avoid accidental collisions with normal KVS keys (Only if you are using same machines for both KV and ANN purposes)
* **RIGHT NOW IT IS NOT SUPPORTED IN THE BIDDING SERVICE** Sharding - if your indexes are too large, consider deploying several instances of KVS, upload

# Final Check & Summary
* Integration: The new getNearestNeighbors hook integrates seamlessly with existing UDF-based read operations by extending the native C++ calls behind the scenes.
* Snapshots: The system can manage multiple snapshots but only actively uses the most recent valid one.
* You must generate embeddings, create snapshots, and store them in the correct location with the correct naming convention.
* Disambiguation: If your KVS is also storing non-ANN data, adopt a prefix or naming scheme to differentiate ANN embeddings.
