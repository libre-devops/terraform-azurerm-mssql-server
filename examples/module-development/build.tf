data "azurerm_client_config" "current" {}

data "http" "client_ip" {
  url = "http://checkip.amazonaws.com/"
}

module "rg" {
  source = "registry.terraform.io/libre-devops/rg/azurerm"

  rg_name  = "rg-${var.short}-${var.loc}-${var.env}-${random_string.entropy.result}"
  location = local.location
  tags     = local.tags

  #  lock_level = "CanNotDelete" // Do not set this value to skip lock
}

module "shared_vars" {
  source = "libre-devops/shared-vars/azurerm"
}

locals {
  lookup_cidr = {
    for landing_zone, envs in module.shared_vars.cidrs : landing_zone => {
      for env, cidr in envs : env => cidr
    }
  }
}

module "subnet_calculator" {
  source = "libre-devops/subnet-calculator/null"

  base_cidr    = local.lookup_cidr[var.short][var.env][0]
  subnet_sizes = [26]
}

module "network" {
  source = "libre-devops/network/azurerm"

  rg_name  = module.rg.rg_name
  location = module.rg.rg_location
  tags     = module.rg.rg_tags

  vnet_name          = "vnet-${var.short}-${var.loc}-${var.env}-01"
  vnet_location      = module.rg.rg_location
  vnet_address_space = [module.subnet_calculator.base_cidr]

  subnets = {
    for i, name in module.subnet_calculator.subnet_names :
    name => {
      address_prefixes  = toset([module.subnet_calculator.subnet_ranges[i]])
      service_endpoints = ["Microsoft.Sql"]

      delegation = []
    }
  }
}

module "mssql_servers" {
  source = "../../"


  mssql_servers = [
    {

      rg_name  = module.rg.rg_name
      location = module.rg.rg_location
      tags     = module.rg.rg_tags

      name                          = "mssql-server-${var.short}-${var.loc}-${var.env}-01"
      identity_type                 = "SystemAssigned"
      public_network_access_enabled = true

      azuread_administrator = {
        login_username              = "LibreDevOpsAdmin"
        tenant_id                   = data.azurerm_client_config.current.tenant_id
        object_id                   = data.azurerm_client_config.current.object_id
        azuread_authentication_only = true
      }

      firewall_rules = [
        {
          name             = "AllowAzureAccess"
          start_ip_address = "0.0.0.0"
          end_ip_address   = "0.0.0.0"
        },
        {
          name             = "AllowLocalAccess"
          start_ip_address = chomp(data.http.client_ip.response_body)
          end_ip_address   = chomp(data.http.client_ip.response_body)
        }
      ]

      vnet_rules = [
        {
          name      = "AllowSubnet1"
          subnet_id = module.network.subnets_ids["subnet1"]
        }
      ]
    }
  ]
}
