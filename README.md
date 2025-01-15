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
| [azurerm_mssql_server.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/mssql_server) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_mssql_servers"></a> [mssql\_servers](#input\_mssql\_servers) | List to deploy mssql servers | <pre>list(object({<br/>    rg_name                                      = string<br/>    location                                     = optional(string, "uksouth")<br/>    tags                                         = map(string)<br/>    name                                         = string<br/>    version                                      = optional(string, "12.0")<br/>    administrator_login                          = optional(string)<br/>    administrator_login_password                 = optional(string)<br/>    identity_type                                = optional(string)<br/>    identity_ids                                 = optional(list(string))<br/>    connection_policy                            = optional(string, "Default")<br/>    transparent_data_encryption_key_vault_key_id = optional(string)<br/>    minimum_tls_version                          = optional(string, "1.2")<br/>    public_network_access_enabled                = optional(bool, false)<br/>    outbound_network_restriction_enabled         = optional(bool, false)<br/>    primary_user_assigned_identity_id            = optional(string)<br/><br/>    azuread_administrator = optional(object({<br/>      login_username              = string<br/>      object_id                   = string<br/>      tenant_id                   = optional(string)<br/>      azuread_authentication_only = optional(bool)<br/>    }))<br/>  }))</pre> | n/a | yes |

## Outputs

No outputs.
