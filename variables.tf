variable "mssql_servers" {
  description = "List to deploy mssql servers"
  type = list(object({
    rg_name                                      = string
    location                                     = optional(string, "uksouth")
    tags                                         = map(string)
    name                                         = string
    version                                      = optional(string, "12.0")
    administrator_login                          = optional(string)
    administrator_login_password                 = optional(string)
    identity_type                                = optional(string)
    identity_ids                                 = optional(list(string))
    connection_policy                            = optional(string, "Default")
    transparent_data_encryption_key_vault_key_id = optional(string)
    minimum_tls_version                          = optional(string, "1.2")
    public_network_access_enabled                = optional(bool, false)
    outbound_network_restriction_enabled         = optional(bool, false)
    primary_user_assigned_identity_id            = optional(string)

    azuread_administrator = optional(object({
      login_username              = string
      object_id                   = string
      tenant_id                   = optional(string)
      azuread_authentication_only = optional(bool)
    }))
  }))
}
