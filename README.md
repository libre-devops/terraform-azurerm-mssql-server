```hcl
resource "azurerm_mssql_server" "this" {
  for_each = { for server in var.mssql_servers : server.name => server }

  location            = each.value.location
  name                = each.value.name
  resource_group_name = each.value.rg_name
  version             = each.value.version

  administrator_login                          = each.value.administrator_login
  administrator_login_password                 = each.value.administrator_login_password
  connection_policy                            = each.value.connection_policy
  transparent_data_encryption_key_vault_key_id = each.value.transparent_data_encryption_key_vault_key_id
  minimum_tls_version                          = each.value.minimum_tls_version
  public_network_access_enabled                = each.value.public_network_access_enabled
  outbound_network_restriction_enabled         = each.value.outbound_network_restriction_enabled
  primary_user_assigned_identity_id            = each.value.primary_user_assigned_identity_id


  dynamic "azuread_administrator" {
    for_each = each.value.azuread_administrator != null ? [each.value.azuread_administrator] : []
    content {
      login_username              = azuread_administrator.value.login_username
      azuread_authentication_only = azuread_administrator.value.azuread_authentication_only
      object_id                   = azuread_administrator.value.object_id
      tenant_id                   = azuread_administrator.value.tenant_id
    }
  }


  dynamic "identity" {
    for_each = each.value.identity_type == "SystemAssigned" ? [each.value.identity_type] : []
    content {
      type = each.value.identity_type
    }
  }

  dynamic "identity" {
    for_each = each.value.identity_type == "SystemAssigned, UserAssigned" ? [each.value.identity_type] : []
    content {
      type         = each.value.identity_type
      identity_ids = try(each.value.identity_ids, [])
    }
  }

  dynamic "identity" {
    for_each = each.value.identity_type == "UserAssigned" ? [each.value.identity_type] : []
    content {
      type         = each.value.identity_type
      identity_ids = length(try(each.value.identity_ids, [])) > 0 ? each.value.identity_ids : []
    }
  }
}

locals {
  combined_firewall_rules = flatten([
    for s in var.mssql_servers : [
      for fw in(s.firewall_rules != null ? s.firewall_rules : []) : {
        server_name = s.name
        rule        = fw
      }
    ]
  ])

  combined_vnet_rules = flatten([
    for s in var.mssql_servers : [
      for vnr in(s.vnet_rules != null ? s.vnet_rules : []) : {
        server_name = s.name
        vnet_rule   = vnr
      }
    ]
  ])
}

resource "azurerm_mssql_firewall_rule" "firewall_rules" {
  # Each item in local.combined_firewall_rules becomes a resource
  for_each = {
    for fr in local.combined_firewall_rules :
    "${fr.server_name}-${fr.rule.name}" => fr
  }

  name             = each.value.rule.name
  server_id        = azurerm_mssql_server.this[each.value.server_name].id
  start_ip_address = each.value.rule.start_ip_address
  end_ip_address   = each.value.rule.end_ip_address
}

resource "azurerm_mssql_virtual_network_rule" "vnet_rules" {
  for_each = {
    for vr in local.combined_vnet_rules :
    "${vr.server_name}-${vr.vnet_rule.name}" => vr
  }

  name      = each.value.vnet_rule.name
  server_id = azurerm_mssql_server.this[each.value.server_name].id
  subnet_id = each.value.vnet_rule.subnet_id
}

resource "azurerm_mssql_server_extended_auditing_policy" "extended_auditing_policies" {
  for_each = {
    for server in var.mssql_servers :
    server.name => server.extended_auditing_policy
    if server.extended_auditing_policy != null
  }

  server_id = azurerm_mssql_server.this[each.key].id

  storage_endpoint = try(each.value.storage_endpoint, null)

  retention_in_days                       = try(each.value.retention_in_days, 0)
  storage_account_access_key              = try(each.value.storage_account_access_key, null)
  storage_account_access_key_is_secondary = try(each.value.storage_account_access_key_is_secondary, false)
  log_monitoring_enabled                  = try(each.value.log_monitoring_enabled, false)
  predicate_expression                    = try(each.value.predicate_expression, null)
  storage_account_subscription_id         = try(each.value.storage_account_subscription_id, null)

  audit_actions_and_groups = try(each.value.audit_actions_and_groups, ["BATCH_COMPLETED_GROUP"])
}

```
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_mssql_firewall_rule.firewall_rules](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/mssql_firewall_rule) | resource |
| [azurerm_mssql_server.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/mssql_server) | resource |
| [azurerm_mssql_server_extended_auditing_policy.extended_auditing_policies](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/mssql_server_extended_auditing_policy) | resource |
| [azurerm_mssql_virtual_network_rule.vnet_rules](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/mssql_virtual_network_rule) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_mssql_servers"></a> [mssql\_servers](#input\_mssql\_servers) | List to deploy mssql servers | <pre>list(object({<br/>    rg_name                                      = string<br/>    location                                     = optional(string, "uksouth")<br/>    tags                                         = map(string)<br/>    name                                         = string<br/>    version                                      = optional(string, "12.0")<br/>    administrator_login                          = optional(string)<br/>    administrator_login_password                 = optional(string)<br/>    identity_type                                = optional(string)<br/>    identity_ids                                 = optional(list(string))<br/>    connection_policy                            = optional(string, "Default")<br/>    transparent_data_encryption_key_vault_key_id = optional(string)<br/>    minimum_tls_version                          = optional(string, "1.2")<br/>    public_network_access_enabled                = optional(bool, false)<br/>    outbound_network_restriction_enabled         = optional(bool, false)<br/>    primary_user_assigned_identity_id            = optional(string)<br/>    azuread_administrator = optional(object({<br/>      login_username              = string<br/>      object_id                   = string<br/>      tenant_id                   = optional(string)<br/>      azuread_authentication_only = optional(bool)<br/>    }))<br/>    firewall_rules = optional(list(object({<br/>      name             = string<br/>      start_ip_address = string<br/>      end_ip_address   = string<br/>    })))<br/>    vnet_rules = optional(list(object({<br/>      name                                 = string<br/>      subnet_id                            = string<br/>      ignore_missing_vnet_service_endpoint = optional(bool, false)<br/>    })))<br/>    extended_auditing_policy = optional(object({<br/>      enabled                                 = optional(bool, true)<br/>      storage_endpoint                        = optional(string)<br/>      retention_in_days                       = optional(number, 0)<br/>      storage_account_access_key              = optional(string)<br/>      storage_account_access_key_is_secondary = optional(bool)<br/>      log_monitoring_enabled                  = optional(bool, true)<br/>      storage_account_subscription_id         = optional(string)<br/>      predicate_expression                    = optional(string)<br/>      audit_actions_and_groups                = optional(list(string), ["BATCH_COMPLETED_GROUP"])<br/>    }))<br/>  }))</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_mssql_firewall_rule_ids"></a> [mssql\_firewall\_rule\_ids](#output\_mssql\_firewall\_rule\_ids) | A map of MSSQL Firewall Rule IDs, keyed by <server>-<rule>. |
| <a name="output_mssql_restorable_dropped_database_ids"></a> [mssql\_restorable\_dropped\_database\_ids](#output\_mssql\_restorable\_dropped\_database\_ids) | The ID of the restorable dropped database. |
| <a name="output_mssql_server_fully_qualified_domain_name"></a> [mssql\_server\_fully\_qualified\_domain\_name](#output\_mssql\_server\_fully\_qualified\_domain\_name) | The fully qualified domain name of the mssql server. |
| <a name="output_mssql_server_id"></a> [mssql\_server\_id](#output\_mssql\_server\_id) | The ID of the mssql server. |
| <a name="output_mssql_server_identity"></a> [mssql\_server\_identity](#output\_mssql\_server\_identity) | The identity of the mssql server. |
| <a name="output_mssql_server_name"></a> [mssql\_server\_name](#output\_mssql\_server\_name) | The name of the mssql server. |
| <a name="output_mssql_vnet_rule_ids"></a> [mssql\_vnet\_rule\_ids](#output\_mssql\_vnet\_rule\_ids) | A map of MSSQL VNet Rule IDs, keyed by <server>-<rule>. |
