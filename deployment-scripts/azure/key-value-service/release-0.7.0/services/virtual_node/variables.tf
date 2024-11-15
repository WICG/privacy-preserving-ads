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
  default     = "vn2"
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "containers" {
  description = "Containers to deploy"
  type = list(object({
    name      = string
    image     = string
    ccepolicy = string
  }))
}
