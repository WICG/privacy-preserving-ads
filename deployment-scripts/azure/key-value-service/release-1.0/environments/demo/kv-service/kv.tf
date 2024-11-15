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
  image_tag      = "prod-1.0.0.0"
}

module "kv-service" {
  source          = "../../../modules/kv-service"
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
      name      = "kv"
      image     = "${local.image_registry}/${local.registry_path}/key-value-service:${local.image_tag}"
      ccepolicy = "${file("../cce-policies/kv.base64")}"
      replicas  = 1
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
        PORT                          = "50051"          # Do not change unless you are modifying the default Azure architecture.
        HEALTHCHECK_PORT              = "50051"          # Do not change unless you are modifying the default Azure architecture.
        AZURE_LOCAL_DATA_DIR          = "/data/deltas"   # Do not change unless you are modifying the default Azure architecture.
        AZURE_LOCAL_REALTIME_DATA_DIR = "/data/realtime" # Do not change unless you are modifying the default Azure architecture.
      }
    }
  ]
  global_runtime_flags = {
    COLLECTOR_ENDPOINT                       = "otel-collector-service.ad_selection.microsoft:4317"
    ENABLE_OTEL_BASED_LOGGING                = "false"            # Example: "false"
    PRIVATE_KEY_CACHE_TTL_SECONDS            = "3888000"          # Example: "3888000"
    PS_VERBOSITY                             = "5"                # Example: "10"
    TELEMETRY_CONFIG                         = "mode: EXPERIMENT" # Example: "mode: EXPERIMENT"
    AZURE_BA_PARAM_GET_TOKEN_URL             = "http://169.254.169.254/metadata/identity/oauth2/token"
    PUBLIC_KEY_ENDPOINT                      = "https://azure.microsoftbrowsertrust.com/app/listpubkeys"
    PRIMARY_COORDINATOR_PRIVATE_KEY_ENDPOINT = "https://azure.microsoftbrowsertrust.com/app/key?fmt=tink"
    AZURE_BA_PARAM_KMS_UNWRAP_URL            = "https://azure.microsoftbrowsertrust.com/app/unwrapKey?fmt=tink"
  }

}
