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

module "seller" {
  source              = "../../../modules/seller"
  environment         = local.environment
  operator            = local.operator
  region              = local.region
  subscription_id     = local.subscription_id
  tenant_id           = local.tenant_id
  private_domain_name = "ad_selection.microsoft"

  # Please refer to documentation https://learn.microsoft.com/en-us/azure/aks/quotas-skus-regions#supported-vm-sizes for node_pool_settings variables
  node_pool_settings = {
    node_count = 2
    vm_size    = "Standard_D4ds_v5"
  }

  containers = [
    {
      name      = "auction-service"
      image     = "${local.image_registry}/${local.registry_path}/auction-service:${local.image_tag}"
      ccepolicy = "${file("../cce-policies/auction.base64")}"
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
        AUCTION_HEALTHCHECK_PORT = "50553" # Do not change unless you are modifying the default Azure architecture.
        AUCTION_PORT             = "50061" # Do not change unless you are modifying the default Azure architecture.

        # TCMalloc related config parameters.
        # See: https://github.com/google/tcmalloc/blob/master/docs/tuning.md
        AUCTION_TCMALLOC_BACKGROUND_RELEASE_RATE_BYTES_PER_SECOND = "4096"        # Example: "4096"
        AUCTION_TCMALLOC_MAX_TOTAL_THREAD_CACHE_BYTES             = "10737418240" # Example: "10737418240"

        ENABLE_AUCTION_SERVICE_BENCHMARK = "" # Example: "false"
        ENABLE_REPORT_WIN_INPUT_NOISING  = "" # Example: "false"
        JS_NUM_WORKERS                   = "" # Example: "64" Must be <= resources.limit.cpu container
        JS_WORKER_QUEUE_LEN              = "" # Example: "200"
        SELLER_CODE_FETCH_CONFIG         = "" # Example:
        # " ${replace(jsonencode(
        #   {
        #     auctionJsPath                   = "",
        #     auctionJsUrl                    = "https://contosa.example/td/sjs",
        #     urlFetchPeriodMs                = 13000000,
        #     urlFetchTimeoutMs               = 30000,
        #     enableSellerDebugUrlGeneration  = false,
        #     enableAdtechCodeLogging         = false,
        #     enableReportResultUrlGeneration = true,
        #     enableReportWinUrlGeneration    = true,
        #     buyerReportWinJsUrls = {
        #       "https://contosa.example" = "https://contosa.example/generateBid.js"
        #     },
        #     protectedAppSignalsBuyerReportWinJsUrls = {
        #       "https://contosa.example" = "https://contosa.example/PASreportWin.js"
        #     }
        # }), ",", "\\,")}"
      }
    },
    {
      name      = "sfe"
      image     = "${local.image_registry}/${local.registry_path}/seller-frontend-service:${local.image_tag}"
      ccepolicy = "${file("../cce-policies/sfe.base64")}"
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
        AUCTION_SERVER_HOST = "auction-service.ad_selection.microsoft:50061" # Do not change unless you are modifying the default Azure architecture.
        BUYER_EGRESS_TLS    = ""
        BUYER_SERVER_HOSTS  = "" # Example:
        # " ${replace(jsonencode(
        #   { "https://contosa.example" : {
        #     "url" : "localhost:50051",
        #     "cloudPlatform" : "LOCAL"
        #     }
        # }), ",", "\\,")}"
        CREATE_NEW_EVENT_ENGINE                = ""
        ENABLE_BUYER_COMPRESSION               = ""
        ENABLE_SELLER_FRONTEND_BENCHMARKING    = "" # Example: "false"
        GET_BID_RPC_TIMEOUT_MS                 = "" # Example: "60000"
        GRPC_ARG_DEFAULT_AUTHORITY             = ""
        KEY_VALUE_SIGNALS_FETCH_RPC_TIMEOUT_MS = "" # Example: "60000"
        KEY_VALUE_SIGNALS_HOST                 = "" # Example: "https://contosa.example/td/sts"
        SCORE_ADS_RPC_TIMEOUT_MS               = "" # Example: "60000"
        SELLER_CLOUD_PLATFORMS_MAP             = ""
        SELLER_FRONTEND_HEALTHCHECK_PORT       = "50551" # Do not change unless you are modifying the default Azure architecture.
        SELLER_FRONTEND_PORT                   = "50051" # Do not change unless you are modifying the default Azure architecture.
        SELLER_ORIGIN_DOMAIN                   = ""      # Example: "https://securepubads.contosa.example"

        # TCMalloc related config parameters.
        # See: https://github.com/google/tcmalloc/blob/master/docs/tuning.md
        SFE_TCMALLOC_BACKGROUND_RELEASE_RATE_BYTES_PER_SECOND = "4096"        # Example: "4096"
        SFE_TCMALLOC_MAX_TOTAL_THREAD_CACHE_BYTES             = "10737418240" # Example: "10737418240"
      }
    }
  ]
  global_runtime_flags = {
    AUCTION_EGRESS_TLS                 = ""
    AZURE_CERT                         = ""           # Example: "tf-demo-seller-usw-kv" auto-generated by Terraform
    AZURE_KEYVAULT_NAME                = ""           # Example: "tf-demo-seller-usw-cert" auto-generated by Terraform
    COLLECTOR_ENDPOINT                 = ""           # Example: "127.0.0.1:4317"
    CONSENTED_DEBUG_TOKEN              = "test-token" # Example: "test-token"
    ENABLE_AUCTION_COMPRESSION         = "false"      # Example: "false"
    ENABLE_CHAFFING                    = "false"      # Example: "false"
    ENABLE_OTEL_BASED_LOGGING          = "false"      # Example: "false"
    ENABLE_PROTECTED_APP_SIGNALS       = "false"      # Example: "false"
    MAX_ALLOWED_SIZE_ALL_DEBUG_URLS_KB = "65536"      # Example: "65536"
    MAX_ALLOWED_SIZE_DEBUG_URL_BYTES   = "3000"       # Example: "3000"
    PS_VERBOSITY                       = "10"         # Example: "10"
    ROMA_TIMEOUT_MS                    = ""
    SFE_INGRESS_TLS                    = ""
    SFE_TLS_CERT                       = ""
    SFE_TLS_KEY                        = ""
    TELEMETRY_CONFIG                   = "" # Example: "mode: EXPERIMENT"

    AZURE_BA_PARAM_GET_TOKEN_URL               = "http://169.254.169.254/metadata/identity/oauth2/token"
    AZURE_BA_PARAM_KMS_UNWRAP_URL              = "https://azure.microsoftbrowsertrust.com/app/unwrapKey?fmt=tink"
    ENABLE_PROTECTED_AUDIENCE                  = "true"
    KEY_REFRESH_FLOW_RUN_FREQUENCY_SECONDS     = "10800"
    PRIMARY_COORDINATOR_ACCOUNT_IDENTITY       = ""
    PRIMARY_COORDINATOR_PRIVATE_KEY_ENDPOINT   = "https://azure.microsoftbrowsertrust.com/app/key?fmt=tink"
    PRIMARY_COORDINATOR_REGION                 = ""
    PRIVATE_KEY_CACHE_TTL_SECONDS              = "3888000"
    PUBLIC_KEY_ENDPOINT                        = "https://azure.microsoftbrowsertrust.com/app/listpubkeys"
    SECONDARY_COORDINATOR_ACCOUNT_IDENTITY     = ""
    SECONDARY_COORDINATOR_PRIVATE_KEY_ENDPOINT = ""
    SECONDARY_COORDINATOR_REGION               = ""
    SFE_PUBLIC_KEYS_ENDPOINTS = " ${replace(jsonencode(
      {
        AZURE = "https://azure.microsoftbrowsertrust.com/app/listpubkeys"
      }),
    ",", "\\,")}"
    TEST_MODE = "false"
  }
}
