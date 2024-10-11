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

################ Common Setup ################

module "regions" {
  source       = "claranet/regions/azurerm"
  version      = "7.2.0"
  azure_region = var.region
}

module "resource_group" {
  source       = "../../services/resource_group"
  operator     = var.operator
  environment  = var.environment
  region       = module.regions.location_cli
  region_short = module.regions.location_short
}

module "networking" {
  source              = "../../services/networking"
  resource_group_name = module.resource_group.name
  operator            = var.operator
  environment         = var.environment
  region              = module.regions.location_cli
  region_short        = module.regions.location_short
}

module "aks" {
  source              = "../../services/aks"
  resource_group_id   = module.resource_group.id
  resource_group_name = module.resource_group.name
  operator            = var.operator
  environment         = var.environment
  region              = module.regions.location_cli
  subnet_id           = module.networking.aks_subnet_id
  virtual_network_id  = module.networking.vnet_id
  region_short        = module.regions.location_short
  node_pool_settings  = var.node_pool_settings
}

module "virtual_node" {
  source               = "../../services/virtual_node"
  kubernetes_namespace = "vn2"
  aks_cluster_name     = module.aks.name
  resource_group_name  = module.resource_group.name
  containers           = var.containers
}

module "app" {
  source                     = "../../services/app"
  kubernetes_namespace       = "default"
  aks_cluster_name           = module.aks.name
  resource_group_name        = module.resource_group.name
  virtual_node_identity_id   = module.aks.virtual_node_identity_id
  containers                 = var.containers
  global_runtime_flags       = var.global_runtime_flags
  storage_account_name       = module.storage_account.name
  file_share_name            = module.storage_account.file_share
  storage_account_access_key = module.storage_account.access_key
}

module "storage_account" {
  source              = "../../services/storage_account"
  operator            = var.operator
  environment         = var.environment
  region              = module.regions.location_cli
  region_short        = module.regions.location_short
  resource_group_name = module.resource_group.name
}
