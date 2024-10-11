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

resource "azurerm_private_dns_zone" "this" {
  name                = var.private_domain_name
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  name                  = "${var.vnet_name}-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.this.name
  virtual_network_id    = var.vnet_id
}

resource "azurerm_user_assigned_identity" "externaldns" {
  name                = "externaldns-identity"
  location            = var.region
  resource_group_name = var.resource_group_name

}

resource "azurerm_federated_identity_credential" "this" {
  name                = "${var.aks_cluster_name}-ServiceAccount-${var.kubernetes_namespace}-${var.kubernetes_service_account}"
  resource_group_name = var.resource_group_name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = var.aks_oidc_issuer_url
  parent_id           = azurerm_user_assigned_identity.externaldns.id
  subject             = "system:serviceaccount:${var.kubernetes_namespace}:${var.kubernetes_service_account}"

  depends_on = [
    azurerm_user_assigned_identity.externaldns,
  ]
}

resource "azurerm_role_assignment" "reader" {
  principal_id                     = azurerm_user_assigned_identity.externaldns.principal_id
  role_definition_name             = "Reader"
  scope                            = var.resource_group_id
  skip_service_principal_aad_check = true

  depends_on = [
    azurerm_user_assigned_identity.externaldns,
  ]
}

resource "azurerm_role_assignment" "private_dns_zone_contributor" {
  principal_id                     = azurerm_user_assigned_identity.externaldns.principal_id
  role_definition_name             = "Private DNS Zone Contributor"
  scope                            = azurerm_private_dns_zone.this.id
  skip_service_principal_aad_check = true

  depends_on = [
    azurerm_private_dns_zone.this,
    azurerm_user_assigned_identity.externaldns,
  ]
}

data "azurerm_kubernetes_cluster" "credentials" {
  name                = var.aks_cluster_name
  resource_group_name = var.resource_group_name

  depends_on = [
    var.aks_cluster_name
  ]
}

provider "helm" {
  debug = true
  kubernetes {
    host                   = data.azurerm_kubernetes_cluster.credentials.kube_config.0.host
    client_certificate     = base64decode(data.azurerm_kubernetes_cluster.credentials.kube_config.0.client_certificate)
    client_key             = base64decode(data.azurerm_kubernetes_cluster.credentials.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.credentials.kube_config.0.cluster_ca_certificate)
  }
}
resource "helm_release" "external_dns" {
  name             = "external-dns"
  namespace        = var.kubernetes_namespace
  chart            = "https://charts.bitnami.com/bitnami/external-dns-6.32.0.tgz"
  create_namespace = true
  cleanup_on_fail  = true

  values = [
    "${file("${path.module}/values.yaml")}"
  ]

  set {
    name  = "azure.useWorkloadIdentityExtension"
    type  = "auto"
    value = "true"
  }

  set {
    name  = "podLabels.azure\\.workload\\.identity/use"
    type  = "string"
    value = "true"
  }

  set {
    name  = "azure.tenantId"
    value = var.tenant_id
  }

  set {
    name  = "azure.resourceGroup"
    value = var.resource_group_name
  }

  set {
    name  = "azure.subscriptionId"
    value = var.subscription_id
  }

  set_list {
    name  = "domainFilters"
    value = ["${var.private_domain_name}"]
  }

  set {
    name  = "serviceAccount.annotations.azure\\.workload\\.identity/client-id"
    value = azurerm_user_assigned_identity.externaldns.client_id
  }
}
