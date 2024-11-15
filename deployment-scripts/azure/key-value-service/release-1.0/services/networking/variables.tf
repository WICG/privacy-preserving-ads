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

variable "operator" {
  description = "Operator name used to identify the resource owner."
  type        = string
}

variable "environment" {
  description = "Assigned environment name to group related resources."
  type        = string
}

variable "region" {
  description = "Azure region"
  type        = string
}

variable "region_short" {
  description = "Azure region shorthand"
  type        = string
}

variable "vnet_address_space" {
  description = "VNET address space"
  type        = string
  default     = "10.0.0.0/14"
}

variable "default_subnet_cidr" {
  description = "Default subnet CIDR"
  type        = string
  default     = "10.0.0.0/24"
}

variable "aks_subnet_cidr" {
  description = "AKS subnet CIDR"
  type        = string
  default     = "10.1.0.0/16"
}

variable "cg_subnet_cidr" {
  description = "Container groups subnet CIDR"
  type        = string
  default     = "10.2.0.0/16"
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}
