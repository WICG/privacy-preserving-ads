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

# Variables related to environment configuration.

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
variable "environment" {
  description = "Assigned environment name to group related resources."
  type        = string
  validation {
    condition     = length(var.environment) <= 10
    error_message = "Due to current naming scheme limitations, environment must not be longer than 10."
  }
}

variable "operator" {
  description = "Operator name used to identify the resource owner."
  type        = string
}

variable "region" {
  description = "Azure region"
  type        = string
}

variable "tenant_id" {
  description = "Azure tenant ID"
  type        = string
}

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "externaldns_kubernetes_namespace" {
  description = "External DNS namespace"
  type        = string
  default     = "external-dns"
}

variable "externaldns_kubernetes_service_account" {
  description = "External DNS service account name"
  type        = string
  default     = "external-dns"
}

variable "node_pool_settings" {
  description = "Node pool settings"
  type = object({
    node_count = number
    vm_size    = string
  })
}

variable "global_runtime_flags" {
  description = "Global runtime flags"
  type        = map(string)
}

variable "custom_aks_workload_identity_id" {
  description = "Azure Kubernetes Service workload identity id"
  type        = string
  nullable    = true
  default     = null
}
