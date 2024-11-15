# Portions Copyright (c) Microsoft Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

locals {
  environment = "demo"
  operator    = "tf"

  # Please refer to https://github.com/claranet/terraform-azurerm-regions/blob/master/REGIONS.md for region codes. Check the "Region Deployments" section in https://github.com/microsoft/virtualnodesOnAzureContainerInstances for regions that support confidential pods.
  region = "westus"

  subscription_id = "<your_subscription_id>"
  tenant_id       = "<your_tenant_id>"

  image_registry = "mcr.microsoft.com"
  registry_path  = "ad-selection/azure"
  image_tag      = "prod-4.3.0.0"
}

module "buyer" {
  source          = "../../../modules/buyer"
  environment     = local.environment
  operator        = local.operator
  region          = local.region
  subscription_id = local.subscription_id
  tenant_id       = local.tenant_id

  # Please refer to documentation https://learn.microsoft.com/en-us/azure/aks/quotas-skus-regions#supported-vm-sizes for node_pool_settings variables
  node_pool_settings = {
    node_count = 3
    vm_size    = "Standard_D4ds_v5"
  }
  containers = [
    {
      name      = "bidding-service"
      image     = "${local.image_registry}/${local.registry_path}/bidding-service:${local.image_tag}"
      ccepolicy = "${file("../cce-policies/bidding.base64")}"
      replicas  = 3
      resources = {
        requests = {
          cpu    = "0.75"
          memory = "2Gi"
        }
        limits = {
          cpu    = "2"
          memory = "8Gi"
        }
      }
      runtime_flags = {
        BIDDING_HEALTHCHECK_PORT = "50551" # Do not change unless you are modifying the default Azure architecture.
        BIDDING_PORT             = "50057" # Do not change unless you are modifying the default Azure architecture.

        # TCMalloc related config parameters.
        # See: https://github.com/google/tcmalloc/blob/master/docs/tuning.md
        BIDDING_TCMALLOC_BACKGROUND_RELEASE_RATE_BYTES_PER_SECOND = "4096"        # Example: "4096"
        BIDDING_TCMALLOC_MAX_TOTAL_THREAD_CACHE_BYTES             = "10737418240" # Example: "10737418240"

        BUYER_CODE_FETCH_CONFIG = "" # Example:
        # " ${replace(jsonencode(
        #   {
        #     fetchMode                               = 0,
        #     biddingJsPath                           = "",
        #     biddingJsUrl                            = "https://bidding.js.example.com/generateBid.js",
        #     protectedAppSignalsBiddingJsUrl         = "https://bidding.signals.js.example.com/generateBid.js",
        #     biddingWasmHelperUrl                    = "",
        #     protectedAppSignalsBiddingWasmHelperUrl = "",
        #     urlFetchPeriodMs                        = 13000000,
        #     urlFetchTimeoutMs                       = 120000,
        #     enableBuyerDebugUrlGeneration           = true,
        #     enableAdtechCodeLogging                 = false,
        #     prepareDataForAdsRetrievalJsUrl         = "",
        #     prepareDataForAdsRetrievalWasmHelperUrl = ""
        # }), ",", "\\,")}" # Escape commas in JSON. A known limitation in the Helm --set flag. https://github.com/hashicorp/terraform-provider-helm/issues/618
        EGRESS_SCHEMA_FETCH_CONFIG = "" # Example:
        # " ${replace(jsonencode(
        #   {
        #     fetchMode         = 0,
        #     egressSchemaUrl   = "https://example.com/egressSchema.json",
        #     urlFetchPeriodMs  = 130000,
        #     urlFetchTimeoutMs = 30000
        # }), ",", "\\,")}" # Escape commas in JSON. A known limitation in the Helm --set flag. https://github.com/hashicorp/terraform-provider-helm/issues/618
        ENABLE_BIDDING_SERVICE_BENCHMARK = "" # Example: "false"
        INFERENCE_SIDECAR_RUNTIME_CONFIG = "" # Example:
        # "{
        #    "num_interop_threads": 4,
        #    "num_intraop_threads": 4,
        #    "module_name": "tensorflow_v2_14_0",
        # }"
        UDF_NUM_WORKERS                                       = "4"   # Example: "64" Must be <= resources.limit.cpu container
        JS_WORKER_QUEUE_LEN                                   = "100" # Example: "200"
        SELECTION_KV_SERVER_ADDR                              = ""
        SELECTION_KV_SERVER_EGRESS_TLS                        = ""
        SELECTION_KV_SERVER_TIMEOUT_MS                        = "" # Example: "60000"
        TEE_AD_RETRIEVAL_KV_SERVER_GRPC_ARG_DEFAULT_AUTHORITY = ""
        TEE_KV_SERVER_GRPC_ARG_DEFAULT_AUTHORITY              = ""
      }
    },
    {
      name      = "bfe"
      image     = "${local.image_registry}/${local.registry_path}/buyer-frontend-service:${local.image_tag}"
      ccepolicy = "${file("../cce-policies/bfe.base64")}"
      replicas  = 3
      resources = {
        requests = {
          cpu    = "0.75"
          memory = "2Gi"
        }
        limits = {
          cpu    = "2"
          memory = "8Gi"
        }
      }
      runtime_flags = {
        BFE_INGRESS_TLS = ""

        # TCMalloc related config parameters.
        # See: https://github.com/google/tcmalloc/blob/master/docs/tuning.md
        BFE_TCMALLOC_BACKGROUND_RELEASE_RATE_BYTES_PER_SECOND = "4096"        # Example: "4096"
        BFE_TCMALLOC_MAX_TOTAL_THREAD_CACHE_BYTES             = "10737418240" # Example: "10737418240"

        BFE_TLS_CERT                                  = ""
        BFE_TLS_KEY                                   = ""
        BIDDING_EGRESS_TLS                            = ""
        BIDDING_SERVER_ADDR                           = "bidding-service.ad_selection.microsoft:50057" # Do not change this unless you are modifying the bidding service
        BIDDING_SIGNALS_LOAD_TIMEOUT_MS               = ""                                             # Example: "60000"
        BUYER_FRONTEND_HEALTHCHECK_PORT               = "50552"                                        # Do not change unless you are modifying the default Azure architecture.
        BUYER_FRONTEND_PORT                           = "50051"                                        # Do not change unless you are modifying the default Azure architecture.
        BUYER_KV_SERVER_ADDR                          = ""                                             # Example: "https://wonderful-smoke-f7f0a95bd29f428f8933d258d315c801.azurewebsites.net"
        BYOS_AD_RETRIEVAL_SERVER                      = ""                                             # Example: "false"
        CREATE_NEW_EVENT_ENGINE                       = ""                                             # Example: "false"
        ENABLE_BIDDING_COMPRESSION                    = ""                                             # Example: "false"
        ENABLE_BUYER_FRONTEND_BENCHMARKING            = ""                                             # Example: "false"
        GENERATE_BID_TIMEOUT_MS                       = ""                                             # Example: "60000"
        GRPC_ARG_DEFAULT_AUTHORITY                    = ""
        PROTECTED_APP_SIGNALS_GENERATE_BID_TIMEOUT_MS = "" # Example: "60000"
      }
    },
    {
      name      = "k-anonymity-service"
      image     = "${local.image_registry}/${local.registry_path}/k-anonymity-service:${local.image_tag}"
      ccepolicy = "${file("../cce-policies/kanon.base64")}"
      replicas  = 3
      resources = {
        requests = {
          cpu    = "0.75"
          memory = "2Gi"
        }
        limits = {
          cpu    = "2"
          memory = "8Gi"
        }
      }
      runtime_flags = {
        ENABLE_K_ANONYMITY_SERVICE_BENCHMARK                    = ""      # Example: "false"
        K_ANONYMITY_HEALTHCHECK_PORT                            = "50543" # Do not change unless you are modifying the default Azure architecture.
        K_ANONYMITY_PORT                                        = "50042" # Do not change unless you are modifying the default Azure architecture.
        KANON_TCMALLOC_BACKGROUND_RELEASE_RATE_BYTES_PER_SECOND = ""      # Example: "4096"
        KANON_TCMALLOC_MAX_TOTAL_THREAD_CACHE_BYTES             = ""      # Example: "10737418240"
        REPLICA_REFRESH_INTERVAL_MIN                            = "60"    # Example: "60"
        TEE_REPLICA_K_ANONYMITY_HOST_ADDR                       = ""      # Example: "localhost:50040"
      }
    }
  ]
  global_runtime_flags = {
    AD_RETRIEVAL_KV_SERVER_ADDR        = ""
    AD_RETRIEVAL_KV_SERVER_EGRESS_TLS  = ""
    AD_RETRIEVAL_TIMEOUT_MS            = "" # Example: "60000"
    BUYER_EGRESS_TLS                   = ""
    COLLECTOR_ENDPOINT                 = ""           # Example: "127.0.0.1:4317"
    CONSENTED_DEBUG_TOKEN              = "test-token" # Example: "test-token"
    ENABLE_AUCTION_COMPRESSION         = "false"      # Example: "false"
    ENABLE_BUYER_COMPRESSION           = "false"      # Example: "false"
    ENABLE_CHAFFING                    = "false"      # Example: "false"
    ENABLE_OTEL_BASED_LOGGING          = "false"      # Example: "false"
    ENABLE_PROTECTED_APP_SIGNALS       = "false"      # Example: "true"
    INFERENCE_MODEL_BUCKET_NAME        = ""
    INFERENCE_MODEL_BUCKET_PATHS       = ""
    INFERENCE_MODEL_CONFIG_PATH        = ""
    INFERENCE_MODEL_FETCH_PERIOD_MS    = "" # Example: "60000"
    INFERENCE_MODEL_LOCAL_PATHS        = ""
    INFERENCE_SIDECAR_BINARY_PATH      = ""
    K_ANONYMITY_SERVER_ADDR            = "k-anonymity-service.ad_selection.microsoft:50042" # Do not change unless you are modifying the default Azure architecture.
    K_ANONYMITY_SERVER_TIMEOUT_MS      = "60000"
    KV_SERVER_EGRESS_TLS               = ""
    MAX_ALLOWED_SIZE_DEBUG_URL_BYTES   = "" # Example: "65536"
    MAX_ALLOWED_SIZE_ALL_DEBUG_URLS_KB = "" # Example: "3000"
    PS_VERBOSITY                       = "" # Example: "10"
    ROMA_TIMEOUT_MS                    = ""
    SELECTION_KV_SERVER_ADDR           = ""
    SELECTION_KV_SERVER_EGRESS_TLS     = ""
    SELECTION_KV_SERVER_TIMEOUT_MS     = "" # Example: "60000"
    TEE_AD_RETRIEVAL_KV_SERVER_ADDR    = ""
    TEE_KV_SERVER_ADDR                 = ""
    TELEMETRY_CONFIG                   = "" # Example: "mode: EXPERIMENT"

    AZURE_BA_PARAM_GET_TOKEN_URL             = "http://169.254.169.254/metadata/identity/oauth2/token"
    AZURE_BA_PARAM_KMS_UNWRAP_URL            = "https://azure.microsoftbrowsertrust.com/app/unwrapKey?fmt=tink"
    ENABLE_PROTECTED_AUDIENCE                = "true"
    KEY_REFRESH_FLOW_RUN_FREQUENCY_SECONDS   = "10800"
    PRIMARY_COORDINATOR_ACCOUNT_IDENTITY     = ""
    PRIMARY_COORDINATOR_PRIVATE_KEY_ENDPOINT = "https://azure.microsoftbrowsertrust.com/app/key?fmt=tink"
    PRIMARY_COORDINATOR_REGION               = ""
    PRIVATE_KEY_CACHE_TTL_SECONDS            = "3888000"
    PUBLIC_KEY_ENDPOINT                      = "https://azure.microsoftbrowsertrust.com/app/listpubkeys"
    SFE_PUBLIC_KEYS_ENDPOINTS = " ${replace(jsonencode(
      {
        AZURE = "https://azure.microsoftbrowsertrust.com/app/listpubkeys"
      }),
    ",", "\\,")}"
    TEST_MODE = "false"
  }

}
