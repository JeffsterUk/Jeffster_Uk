module "resource_groups" {
  source   = "github.com/JeffsterUk/Terraform_Modules/Modules/azurerm_resource_group"
  for_each = toset(concat(local.hub.resource_groups, local.mgt.resource_groups))

  name     = each.key
  location = local.globals.location
  tags     = local.globals.tags
}

module "network_security_groups" {
  source   = "github.com/JeffsterUk/Terraform_Modules/Modules/azurerm_nsg"
  for_each = { for nsg in concat(local.hub.network_security_groups, local.mgt.network_security_groups) : nsg.name => nsg }

  name                       = each.key
  resource_group_name        = module.resource_groups[each.value.resource_group_name].name
  location                   = local.globals.location
  nsg_rules                  = each.value.rules
  tags                       = local.globals.tags
  log_analytics_workspace_id = null # data.azurerm_log_analytics_workspace.this.id
  enable_diagnostic_settings = false
}

module "route_tables" {
  source   = "github.com/JeffsterUk/Terraform_Modules/Modules/azurerm_route"
  for_each = { for route_table in concat(local.hub.route_tables, local.mgt.route_tables) : route_table.name => route_table }

  route_table_name    = each.key
  resource_group_name = module.resource_groups[each.value.resource_group_name].name
  location            = local.globals.location
  routes              = each.value.routes
  tags                = local.globals.tags
}

module "virtual_networks" {
  source   = "github.com/JeffsterUk/Terraform_Modules/Modules/azurerm_vnet"
  for_each = { for virtual_network in concat(local.hub.virtual_networks, local.mgt.virtual_networks) : virtual_network.name => virtual_network }

  name                       = each.key
  resource_group_name        = module.resource_groups[each.value.resource_group_name].name
  location                   = local.globals.location
  address_space              = each.value.address_space
  dns_servers                = each.value.dns_servers
  enable_diagnostic_settings = false # TODO: Need to implement this
  log_analytics_workspace_id = null
  tags                       = local.globals.tags
}

module "subnets" {
  source = "github.com/JeffsterUk/Terraform_Modules/Modules/azurerm_subnet"
  for_each = merge(flatten([
    for virtual_network in concat(local.hub.virtual_networks, local.mgt.virtual_networks) : merge({
      for subnet in virtual_network.subnets : "${virtual_network.name}\\${subnet.name}" => {
        name                   = subnet.name
        virtual_network        = virtual_network.name
        resource_group         = virtual_network.resource_group_name
        address_prefixes       = subnet.address_prefixes
        service_endpoints      = try(subnet.service_endpoints, [])
        network_security_group = subnet.network_security_group
        route_table            = subnet.route_table
        delegation             = try(subnet.delegation, [])
      }
    })
  ])...)

  name                 = each.value.name
  resource_group_name  = each.value.resource_group
  virtual_network_name = module.virtual_networks[each.value.virtual_network].vnet_name
  address_prefixes     = each.value.address_prefixes
  service_endpoints    = each.value.service_endpoints
  nsg_details = {
    is_nsg_subnet_association_required = each.value.network_security_group == null ? false : true
    nsg_id                             = each.value.network_security_group == null ? null : module.network_security_groups[each.value.network_security_group].nsg_id
  }
  route_table_details = {
    is_route_table_subnet_association_required = each.value.route_table == null ? false : true
    route_table_id                             = each.value.route_table == null ? null : module.route_tables[each.value.route_table].route_table_id
  }
  delegation = each.value.delegation
}

module "virtual_network_peering" {
  source    = "github.com/JeffsterUk/Terraform_Modules/Modules/azurerm_virtual_network_peering"
  providers = { azurerm.hub_subscription = azurerm }
  for_each  = { for virtual_network_peering in local.hub.virtual_network_peerings : virtual_network_peering.id => virtual_network_peering }

  hub_allow_forwarded_traffic               = each.value.hub_allow_forwarded_traffic
  hub_allow_gateway_transit                 = each.value.hub_allow_gateway_transit
  hub_allow_virtual_network_access          = each.value.hub_allow_virtual_network_access
  hub_subscription_id                       = each.value.hub_subscription_id
  hub_virtual_network_resource_group_name   = each.value.hub_virtual_network_resource_group_name
  hub_virtual_network_name                  = each.value.hub_virtual_network_name
  hub_use_remote_gateways                   = each.value.hub_use_remote_gateways
  spoke_allow_forwarded_traffic             = each.value.spoke_allow_forwarded_traffic
  spoke_allow_gateway_transit               = each.value.spoke_allow_gateway_transit
  spoke_allow_virtual_network_access        = each.value.spoke_allow_virtual_network_access
  spoke_virtual_network_resource_group_name = each.value.spoke_virtual_network_resource_group_name
  spoke_virtual_network_name                = each.value.spoke_virtual_network_name
  spoke_use_remote_gateways                 = each.value.spoke_use_remote_gateways
  spoke_subscription_id                     = each.value.hub_subscription_id
  depends_on                                = [module.virtual_networks]
}

module "private_dns_zones" {
  source    = "../../Terraform_Modules/Modules/azure_private_dns_zone"
  providers = { azurerm.hub_subscription = azurerm }
  for_each  = toset(local.hub.private_dns.zones)

  name                = each.value
  resource_group_name = local.hub.private_dns.resource_group_name
  virtual_network_links = [{
    name               = local.hub.private_dns.virtual_network_links.name
    virtual_network_id = module.virtual_networks[local.hub.private_dns.virtual_network_links.name].vnet_id
  }]
  tags       = local.globals.tags
  depends_on = [module.virtual_networks]
}