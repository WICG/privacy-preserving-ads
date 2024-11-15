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

output "name" {
  description = "Storage account"
  value       = azurerm_storage_account.this.name
}

output "file_share" {
  description = "Fileshare name"
  value       = azurerm_storage_share.this.name
}

output "file_share_id" {
  description = "Fileshare id"
  value       = azurerm_storage_share.this.id
}

output "access_key" {
  description = "Storage account access key"
  value       = azurerm_storage_account.this.primary_access_key
}
