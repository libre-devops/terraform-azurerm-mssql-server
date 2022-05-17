variable "rg_name" {
  description = "The name of the resource group, this module does not create a resource group, it is expecting the value of a resource group already exists"
  type        = string
  validation {
    condition     = length(var.rg_name) > 1 && length(var.rg_name) <= 24
    error_message = "Resource group name is not valid."
  }
}

variable "location" {
  description = "The location for this resource to be put in"
  type        = string
}

variable "sql_server_name" {
  description = "The name of the SQL Server that will be deployed."
  type        = string
  default     = "LibreDevOpsSQL"
}

variable "administrator_login" {
  description = "The admin username of the VM that will be deployed."
  type        = string
  default     = "LibreDevOpsAdmin"
}

variable "administrator_login_password" {
  description = "The admin password to be used on the VMSS that will be deployed. The password must meet the complexity requirements of Azure."
  type        = string
  default     = ""
  sensitive   = true
}

variable "sql_version" {
  description = "The admin username of the VM that will be deployed."
  default     = "12.0"
}

variable "azuread_administrator_emails" {
  description = ""
  type        = list(string)
}

variable "connection_policy" {
  default = "Default"
}

variable "sa_primary_access_key" {

}

variable "sa_blob_endpoint" {

}

variable "sa_blob_name" {

}

variable "db_threat_detection_state" {
  default = "Enabled"
}

variable "db_threat_detection_disabled_alerts" {
  default = []

}

variable "identity_type" {
  default = "SystemAssigned"
}

variable "sql_audit_retention_days" {
  default = "90"
}

variable "public_network_access_enabled" {
  default = "false"
}

variable "common_tags" {
}

