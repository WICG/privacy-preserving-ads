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

variable "aks_cluster_name" {
  description = "Azure Kubernetes Service cluster name"
  type        = string
}

variable "kubernetes_namespace" {
  description = "Virtual Node namespace"
  type        = string
  default     = "default"
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "side" {
  description = "Whether buyer or seller"
  type        = string
}

variable "key_vault_name" {
  description = "Key Vault"
  type        = string
}

variable "sfe_certificate_name" {
  description = "SFE Certificate name"
  type        = string
}

variable "containers" {
  description = "Containers to deploy"
  type = list(object({
    name      = string
    image     = string
    ccepolicy = string
    replicas  = number
    resources = object({
      requests = map(string)
      limits   = map(string)
    })
    runtime_flags = map(string)
  }))
}

variable "virtual_node_identity_id" {
  description = "Virtual Node managed identity id"
  type        = string
}
variable "global_runtime_flags" {
  description = "Global runtime flags"
  type        = map(string)
}
