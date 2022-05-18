variable "location" {
  default     = "UK South"
  description = "The location where the resources should be created."
}

variable "rg_name" {
  description = "The name of the resource group, this module does not create a resource group, it is expecting the value of a resource group already exists"
  type        = string
  validation {
    condition     = length(var.rg_name) > 1 && length(var.rg_name) <= 24
    error_message = "Resource group name is not valid."
  }
}

variable "administrator_login_password" {
  description = "The admin password to be used on the VMSS that will be deployed. The password must meet the complexity requirements of Azure."
  type        = string
  default     = ""
  sensitive   = true
}

variable "server_name" {
}

variable "sql_version" {
}

variable "administrator_login" {
}

variable "connection_policy" {
  default = "Default"
}

variable "identity_type" {
  default = "SystemAssigned"
}

variable "public_network_access_enabled" {
  default = "false"
}