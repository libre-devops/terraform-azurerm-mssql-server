resource "azurerm_mssql_server" "sql_server" {

  name                          = var.server_name
  resource_group_name           = var.rg_name
  location                      = var.location
  version                       = var.sql_version
  administrator_login           = var.administrator_login
  administrator_login_password  = var.administrator_login_password
  connection_policy             = var.connection_policy
  public_network_access_enabled = var.public_network_access_enabled
  minimum_tls_version           = "1.2"

  identity {
    type = var.identity_type
  }

}

resource "azurerm_mssql_firewall_rule" "allow_trusted_azure" {
  name                = "AllowTrustedAzureServices"
  server_id           = azurerm_mssql_server.sql_server.id
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}