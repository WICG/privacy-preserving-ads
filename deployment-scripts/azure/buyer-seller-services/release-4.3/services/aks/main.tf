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

resource "azurerm_kubernetes_cluster" "aks" {
  name                      = "${var.operator}-${var.environment}-${var.frontend_service_name}-${var.region_short}-aks"
  location                  = var.region
  resource_group_name       = var.resource_group_name
  dns_prefix                = "${var.operator}-${var.environment}-${var.frontend_service_name}-${var.region_short}-aks-dns"
  kubernetes_version        = var.kubernetes_version
  workload_identity_enabled = true
  oidc_issuer_enabled       = true
  automatic_upgrade_channel = "patch"

  network_profile {
    network_plugin     = "azure"
    network_policy     = "calico"
    network_data_plane = "azure"
    load_balancer_sku  = "standard"
    service_cidr       = var.service_cidr
    dns_service_ip     = var.dns_service_ip
    outbound_type      = "loadBalancer"
    service_cidrs      = [var.service_cidr]
  }

  default_node_pool {
    name           = "default"
    node_count     = var.node_pool_settings.node_count
    vm_size        = var.node_pool_settings.vm_size
    os_sku         = "Ubuntu"
    vnet_subnet_id = var.subnet_id

    upgrade_settings {
      drain_timeout_in_minutes      = 0
      max_surge                     = "10%"
      node_soak_duration_in_minutes = 0
    }
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "aks_identity_rg_contributor" {
  principal_id                     = azurerm_kubernetes_cluster.aks.identity[0].principal_id
  role_definition_name             = "Contributor"
  scope                            = var.resource_group_id
  skip_service_principal_aad_check = true

  depends_on = [
    azurerm_kubernetes_cluster.aks,
  ]
}

resource "azurerm_role_assignment" "aks_identity_vnet_reader" {
  principal_id                     = azurerm_kubernetes_cluster.aks.identity[0].principal_id
  role_definition_name             = "Reader"
  scope                            = var.virtual_network_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "aks_kubeidentity_rg_contributor" {
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name             = "Contributor"
  scope                            = var.resource_group_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "aks_kubeidentity_mcrg_contributor" {
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name             = "Contributor"
  scope                            = azurerm_kubernetes_cluster.aks.node_resource_group_id
  skip_service_principal_aad_check = true
}

resource "azurerm_user_assigned_identity" "this" {
  name                = "virtual-node-identity"
  location            = var.region
  resource_group_name = var.resource_group_name
}
