#tfsec:ignore:azure-database-enable-audit
resource "azurerm_mssql_server" "sql_server" {

  name                          = "${var.sql_server_name}${format("%02d", count.index + 1)}"
  resource_group_name           = var.rg_name
  location                      = var.location
  version                       = var.sql_version
  administrator_login           = var.administrator_login
  administrator_login_password  = var.administrator_login_password
  connection_policy             = var.connection_policy
  public_network_access_enabled = var.public_network_access_enabled
  minimum_tls_version           = "1.2"

  tags = var.common_tags

  identity {
    type = var.identity_type
  }

}

#tfsec:azure-mssql-all-threat-alerts-enabled
#tfsec:ignore:azure-database-threat-alert-email-set
resource "azurerm_mssql_server_security_alert_policy" "sql_alerts" {

  resource_group_name  = var.rg_name
  server_name          = azurerm_mssql_server.sql_server.name
  state                = var.db_threat_detection_state
  disabled_alerts      = []
  retention_days       = var.sql_audit_retention_days
  email_account_admins = true
  email_addresses      = var.azuread_administrator_emails
}

resource "azurerm_mssql_firewall_rule" "allow_trusted_azure" {
  name                = "AllowTrustedAzureServices"
  server_id           = azurerm_mssql_server.sql_server.id
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

resource "azurerm_mssql_server_vulnerability_assessment" "sql_vulnerability" {

  depends_on = [azurerm_mssql_firewall_rule.allow_trusted_azure]

  server_security_alert_policy_id = azurerm_mssql_server_security_alert_policy.sql_alerts.id
  storage_container_path          = "${var.sa_blob_endpoint}${var.sa_blob_name}/"

  recurring_scans {
    enabled                   = true
    email_subscription_admins = true
    emails                    = var.azuread_administrator_emails

  }

  timeouts {
    create = "5m"
    delete = "5m"
    update = "5m"
  }
}

resource "azurerm_mssql_server_extended_auditing_policy" "sql_db_audit" {
  server_id              = azurerm_mssql_server.sql_server.id
  log_monitoring_enabled = true
  retention_in_days      = var.sql_audit_retention_days
}