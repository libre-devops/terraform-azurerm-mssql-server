output "sql_server_name" {
  description = "Name of the server created. Use this if more databases needs to be added to the server. "
  value       = azurerm_mssql_server.sql_server.name
}

output "sql_server_id" {
  value = azurerm_mssql_server.sql_server.id
}

output "sql_server_principal_id" {
  value = azurerm_mssql_server.sql_server.identity.0.principal_id
}

output "sql_server_tenant_id" {
  value = azurerm_mssql_server.sql_server.identity.0.tenant_id
}
