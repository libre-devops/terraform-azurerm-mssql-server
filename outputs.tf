output "mssql_restorable_dropped_database_ids" {
  description = "The ID of the restorable dropped database."
  value       = { for server in azurerm_mssql_server.this : server.name => server.restorable_dropped_database_ids }
}

output "mssql_server_fully_qualified_domain_name" {
  description = "The fully qualified domain name of the mssql server."
  value       = { for server in azurerm_mssql_server.this : server.name => server.fully_qualified_domain_name }
}

output "mssql_server_id" {
  description = "The ID of the mssql server."
  value       = { for server in azurerm_mssql_server.this : server.name => server.id }
}

output "mssql_server_identity" {
  description = "The identity of the mssql server."
  value       = { for server in azurerm_mssql_server.this : server.name => server.identity }
}

output "mssql_server_name" {
  description = "The name of the mssql server."
  value       = { for server in azurerm_mssql_server.this : server.name => server.name }
}
