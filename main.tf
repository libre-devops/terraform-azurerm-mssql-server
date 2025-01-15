resource "azurerm_mssql_server" "this" {
  for_each = { for server in var.mssql_servers : server.name => server }

  location            = each.value.location
  name                = each.value.name
  resource_group_name = each.value.rg_name
  version             = each.value.version

  administrator_login          = each.value.administrator_login
  administrator_login_password = each.value.administrator_login_password




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