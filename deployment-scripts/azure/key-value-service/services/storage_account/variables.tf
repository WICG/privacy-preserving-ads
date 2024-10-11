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
  description = "Operator"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9]*$", var.operator))
    error_message = "The input_variable can only contain alphanumeric characters (a-z, A-Z, 0-9)."
  }
}

variable "environment" {
  description = "Environment"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9]*$", var.environment))
    error_message = "The input_variable can only contain alphanumeric characters (a-z, A-Z, 0-9)."
  }
}

variable "region" {
  description = "Azure region"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9]*$", var.region))
    error_message = "The input_variable can only contain alphanumeric characters (a-z, A-Z, 0-9)."
  }
}

variable "region_short" {
  description = "Azure region short name"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9]*$", var.region_short))
    error_message = "The input_variable can only contain alphanumeric characters (a-z, A-Z, 0-9)."
  }
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}
