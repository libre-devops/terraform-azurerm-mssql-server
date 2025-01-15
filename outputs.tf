output "mssql_firewall_rule_ids" {
  description = "A map of MSSQL Firewall Rule IDs, keyed by <server>-<rule>."
  value = {
    for rule_key, rule_res in azurerm_mssql_firewall_rule.firewall_rules :
    rule_key => rule_res.id
  }
}

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

output "mssql_vnet_rule_ids" {
  description = "A map of MSSQL VNet Rule IDs, keyed by <server>-<rule>."
  value = {
    for rule_key, rule_res in azurerm_mssql_virtual_network_rule.vnet_rules :
    rule_key => rule_res.id
  }
}
