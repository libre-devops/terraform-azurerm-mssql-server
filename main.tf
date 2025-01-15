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


resource "azurerm_mssql_server_security_alert_policy" "security_alert_policies" {
  for_each = {
    for s in var.mssql_servers :
    s.name => s
    if s.security_alert_policy != null
    && try(s.security_alert_policy.state, "Enabled") != "Disabled"
  }

  resource_group_name        = azurerm_mssql_server.this[each.key].resource_group_name
  server_name                = azurerm_mssql_server.this[each.key].name
  state                      = try(each.value.security_alert_policy.state, "Enabled")
  storage_endpoint           = try(each.value.security_alert_policy.storage_endpoint, azurerm_storage_account.example.primary_blob_endpoint)
  storage_account_access_key = try(each.value.security_alert_policy.storage_account_access_key, azurerm_storage_account.example.primary_access_key)
  retention_days             = try(each.value.security_alert_policy.retention_days, 0)
  disabled_alerts            = try(each.value.security_alert_policy.disabled_alerts, [])
  email_account_admins       = try(each.value.security_alert_policy.email_account_admins, "Disabled")
  email_addresses            = try(each.value.security_alert_policy.email_addresses, [])
}

resource "azurerm_mssql_server_vulnerability_assessment" "vulnerability_assessment" {
  for_each = {
    for s in var.mssql_servers :
    s.name => s
    if s.vulnerability_assessment != null
    && try(s.vulnerability_assessment.enabled, false) == true
    && contains(keys(azurerm_mssql_server_security_alert_policy.security_alert_policies), s.name)
  }

  server_security_alert_policy_id = azurerm_mssql_server_security_alert_policy.security_alert_policies[each.key].id
  storage_container_path          = each.value.vulnerability_assessment.storage_container_path
  storage_container_access_key    = each.value.vulnerability_assessment.storage_container_access_key
  storage_container_sas_key       = each.value.vulnerability_assessment.storage_container_sas_key


  dynamic "recurring_scans" {
    for_each = each.value.vulnerability_assessment.recurring_scans != null ? [each.value.vulnerability_assessment.recurring_scans] : []
    content {
      enabled                   = recurring_scans.value.enabled
      email_subscription_admins = recurring_scans.value.email_subscription_admins
      emails                    = recurring_scans.value.emails
    }
  }
}
