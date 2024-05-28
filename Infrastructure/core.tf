module "resource_groups" {
  source   = "..\\..\\Terraform_Modules\\Modules\\azurerm_resource_group"
  for_each = toset(local.all.resource_groups)

  name     = each.key
  location = local.globals.region
  tags     = local.globals.tags
}

module "virtual_networks" {
  source   = "..\\..\\Terraform_Modules\\Modules\\azurerm_vnet"
  for_each = { for virtual_network in local.all.virtual_networks : virtual_network.name => virtual_network }

  name                       = each.key
  resource_group_name        = module.resource_groups[each.value.resource_group_name].name
  location                   = local.globals.region
  address_space              = each.value.address_space
  dns_servers                = each.value.dns_servers
  enable_diagnostic_settings = false
  log_analytics_workspace_id = null
  tags                       = local.globals.tags
}


module "subnets" {
  source = "..\\..\\Terraform_Modules\\Modules\\azurerm_subnet"
  for_each = [
    for virtual_network in local.all.virtual_networks : merge({
      for subnet in virtual_network.subnets : "${virtual_network.name}\\${subnet.name}" => {
        name                   = subnet.name
        virtual_network        = virtual_network.name
        resource_group         = module.resource_groups[virtual_network.resource_group_name].name
        address_prefixes       = subnet.address_prefixes
        service_endpoints      = [] # subnet.service_endpoints
        network_security_group = subnet.network_security_group
        route_table            = subnet.route_table
        delegation             = [] # subnet.delegation
      }
    })
  ][0]

  name                 = each.value.name
  resource_group_name  = module.resource_groups[each.value.resource_group].name
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

module "network_security_groups" {
  source   = "..\\..\\Terraform_Modules\\Modules\\azurerm_nsg"
  for_each = { for nsg in local.all.network_security_groups : nsg.name => nsg }

  name                       = each.key
  resource_group_name        = module.resource_groups[each.value.resource_group_name].name
  location                   = local.globals.region
  nsg_rules                  = each.value.rules
  tags                       = local.globals.tags
  log_analytics_workspace_id = null # data.azurerm_log_analytics_workspace.this.id
  enable_diagnostic_settings = false
}

module "route_tables" {
  source   = "..\\..\\Terraform_Modules\\Modules\\azurerm_route"
  for_each = { for route_table in local.all.route_tables : route_table.name => route_table }

  route_table_name    = each.key
  resource_group_name = module.resource_groups[each.value.resource_group_name].name
  location            = local.globals.region
  routes              = each.value.routes
  tags                = local.globals.tags
}

module "private_dns_zones" {
  source    = "..\\..\\Terraform_Modules\\Modules\\azurerm_private_dns_zone"
  providers = { azurerm.hub_subscription = azurerm }
  for_each  = toset(local.hub.private_dns_zones)

  name                = each.key
  resource_group_name = "JFSTR-PROD-HUB-CORE-NETWORK-UKS-RG"
  virtual_networks    = [
    {
      name                = "JFSTR-PROD-HUB-CORE-UKS-VNET-001"
      resource_group_name = "JFSTR-PROD-HUB-CORE-NETWORK-UKS-RG"
    }
  ]
  tags                = local.globals.tags
}

module "log_analytics_workspaces" {
  source    = "..\\..\\Terraform_Modules\\Modules\\azurerm_log_analytics_workspace"
  for_each  = { for law in local.all.log_analytics_workspaces : law.name => law }

  name                = each.value.name
  location            = local.globals.region
  resource_group_name = module.resource_groups[each.value.resource_group_name].name
  sku                 = each.value.sku
  retention_in_days   = each.value.retention_in_days
  tags                = local.globals.tags
}

# TODO: AMPLS Module Required
resource "azurerm_monitor_private_link_scope" "management" {
  name                = "${local.globals.company_prefix}-${local.globals.environment}-MGT-LOG-NETWORK-UKS-AMPLS"
  resource_group_name = "${local.globals.company_prefix}-${local.globals.environment}-MGT-LOG-NETWORK-UKS-RG"
}

resource "azurerm_private_endpoint" "management" {
  name                          = "${local.globals.company_prefix}-${local.globals.environment}-MGT-LOG-NETWORK-UKS-AMPLS-PE"
  location                      = local.globals.region
  resource_group_name           = "${local.globals.company_prefix}-${local.globals.environment}-MGT-LOG-NETWORK-UKS-RG"
  subnet_id                     = module.subnets["JFSTR-PROD-HUB-CORE-UKS-VNET-001\\PRIVATE-ENDPOINTS-SNET"].subnet_id
  custom_network_interface_name = "${local.globals.company_prefix}-${local.globals.environment}-MGT-LOG-NETWORK-UKS-AMPLS-PE-NIC"

  private_service_connection {
    name                           = "${local.globals.company_prefix}-${local.globals.environment}-MGT-LOG-NETWORK-UKS-AMPLS-PE"
    private_connection_resource_id = azurerm_monitor_private_link_scope.management.id
    is_manual_connection           = false
    subresource_names              = ["azuremonitor"]
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [
      for pdnsz in [
        "privatelink.monitor.azure.com",
        "privatelink.oms.opinsights.azure.com",
        "privatelink.ods.opinsights.azure.com",
        "privatelink.agentsvc.azure-automation.net",
        "privatelink.blob.core.windows.net"
      ] : module.private_dns_zones[pdnsz].id
    ]
  }
}

# module "key_vaults" {
  
# }

# module "storage_accounts" {
  
# }

# module "private_dns_a_record" {
#   source   = "git@ssh.dev.azure.com:v3/RBGKew/AzureLandingZone/lz-terraform-modules//azurerm_private_dns_a_record?ref=v2.0.0"
#   for_each = { for private_dns_a_record in var.region.private_dns_a_records : private_dns_a_record.name => private_dns_a_record }

#   dns_a_record_name     = each.key
#   private_dns_zone_name = each.value.private_dns_zone_name
#   resource_group_name   = module.resource_groups[each.value.resource_group_name].name
#   records               = each.value.private_dns_a_record_addresses
#   tags                  = var.tfvars.tags
# }

# module "web_application_firewall_policy" {
#   source   = "git@ssh.dev.azure.com:v3/RBGKew/AzureLandingZone/lz-terraform-modules//azurerm_web_application_firewall_policy?ref=v2.0.0"
#   for_each = { for web_application_firewall_policy in var.region.web_application_firewall_policys : web_application_firewall_policy.name => web_application_firewall_policy }

#   name                = each.key
#   resource_group_name = module.resource_groups[each.value.resource_group_name].name
#   location            = var.region.location

#   custom_rules    = each.value.custom_rules
#   policy_settings = each.value.policy_settings
#   managed_rules   = each.value.managed_rules
#   tags            = var.tfvars.tags
# }

# module "app_gateways" {
#   source   = "git@ssh.dev.azure.com:v3/RBGKew/AzureLandingZone/lz-terraform-modules//azurerm_application_gateway?ref=v2.0.0"
#   for_each = { for app_gateway in var.region.app_gateways : app_gateway.name => app_gateway }

#   name                       = each.key
#   autoscale_configuration    = each.value.autoscale_configuration
#   backend_address_pool       = each.value.backend_address_pool
#   backend_http_settings      = each.value.backend_http_settings
#   custom_error_configuration = each.value.custom_error_configuration
#   enable_http2               = each.value.enable_http2
#   firewall_policy_id         = module.web_application_firewall_policy[each.value.firewall_policy_name].web_application_firewall_policy_id

#   frontend_ip_configuration                = each.value.frontend_ip_configuration
#   frontend_port                            = each.value.frontend_port
#   gateway_ip_configuration                 = each.value.gateway_ip_configuration
#   http_listener                            = each.value.http_listener
#   identity_type                            = each.value.identity_id != "" ? "UserAssigned" : null
#   identity_ids                             = [each.value.identity_id]
#   location                                 = var.region.location
#   probe                                    = each.value.probe
#   public_ip_allocation_method              = each.value.public_ip_allocation_method
#   public_ip_name                           = each.value.public_ip_name
#   public_ip_sku                            = each.value.public_ip_sku
#   redirect_configuration                   = each.value.redirect_configuration
#   request_routing_rule                     = each.value.request_routing_rule
#   resource_group_name                      = each.value.resource_group_name
#   rewrite_rule_set                         = each.value.rewrite_rule_set
#   sku                                      = each.value.sku
#   ssl_certificate                          = each.value.ssl_certificate
#   ssl_policy                               = each.value.ssl_policy
#   tags                                     = var.tfvars.tags
#   trusted_root_certificate                 = each.value.trusted_root_certificate
#   url_path_map                             = each.value.url_path_map
#   waf_configuration                        = each.value.waf_configuration
#   zones                                    = each.value.zones
#   subnet_info                              = { for s in module.subnets : s.subnet_name => s.subnet_id }
#   log_analytics_workspace_id               = data.azurerm_log_analytics_workspace.this.id
#   enable_diagnostic_settings               = var.region.enable_diagnostic_settings
#   ddos_protection_plan_name                = each.value.ddos_protection_plan_name
#   ddos_protection_plan_resource_group_name = each.value.ddos_protection_plan_resource_group_name
#   ddos_protection_mode                     = each.value.ddos_protection_mode

#   depends_on = [module.user_assigned_identity]
# }

module "virtual_network_peering" {
  source    = "..\\..\\Terraform_Modules\\Modules\\azurerm_virtual_network_peering"
  providers = { azurerm.hub_subscription = azurerm }
  for_each  = { for virtual_network_peering in local.all.virtual_network_peerings : virtual_network_peering.id => virtual_network_peering }

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
  spoke_subscription_id                     = each.value.hub_subscription_id # TODO: Fix
}

# module "user_assigned_identity" {
#   source   = "git@ssh.dev.azure.com:v3/RBGKew/AzureLandingZone/lz-terraform-modules//azurerm_user_assigned_identity?ref=v2.0.0"
#   for_each = { for user_assigned_identity in var.region.user_assigned_identitys : user_assigned_identity.name => user_assigned_identity }

#   name                = each.key
#   location            = var.region.location
#   resource_group_name = each.value.resource_group_name
#   tags                = var.tfvars.tags
# }

# module "network_ddos" {
#   source   = "git@ssh.dev.azure.com:v3/RBGKew/AzureLandingZone/lz-terraform-modules//azurerm_network_ddos_protection_plan?ref=v2.0.0"
#   for_each = { for network_ddos_protection_plan in var.region.network_ddos_protection_plans : network_ddos_protection_plan.name => network_ddos_protection_plan }

#   ddos_name           = each.key
#   location            = var.region.location
#   resource_group_name = each.value.resource_group_name
#   tags                = var.tfvars.tags
# }