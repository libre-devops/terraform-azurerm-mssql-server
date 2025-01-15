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

    firewall_rules = optional(list(object({
      name             = string
      start_ip_address = string
      end_ip_address   = string
    })))
    vnet_rules = optional(list(object({
      name                                 = string
      subnet_id                            = string
      ignore_missing_vnet_service_endpoint = optional(bool, false)
    })))
    extended_auditing_policy = optional(object({
      enabled                                 = optional(bool, false)
      storage_endpoint                        = optional(string)
      retention_in_days                       = optional(number)
      storage_account_access_key              = optional(string)
      storage_account_access_key_is_secondary = optional(bool)
      log_monitoring_enabled                  = optional(bool)
      storage_account_subscription_id         = optional(string)
      predicate_expression                    = optional(string)
      audit_actions_and_groups                = optional(list(string), ["BATCH_COMPLETED_GROUP"])

    }))
  }))
}
