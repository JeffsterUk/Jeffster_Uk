module "azure_monitor_private_link_scope" {
  source   = "github.com/JeffsterUk/Terraform_Modules/Modules/azurerm_monitor_private_link_scope"

  name                = local.mgt.azure_monitor_private_link_scope.name
  resource_group_name = local.mgt.azure_monitor_private_link_scope.resource_group_name
  private_endpoint    = {
    name                            = local.mgt.azure_monitor_private_link_scope.private_endpoint.name
    location                        = local.globals.location
    subnet_id                       = module.subnets[local.mgt.azure_monitor_private_link_scope.private_endpoint.private_endpoint_subnet].subnet_id
    custom_network_interface_name   = local.mgt.azure_monitor_private_link_scope.private_endpoint.custom_network_interface_name
    private_service_connection_name = local.mgt.azure_monitor_private_link_scope.private_endpoint.private_service_connection_name
    private_dns_zone_ids            = [ 
      for pdnsz in module.private_dns_zones : pdnsz.id 
      if contains( local.mgt.azure_monitor_private_link_scope.private_endpoint.private_dns_zones, pdnsz.name)
    ]
  }
  scoped_services = [ for law in local.mgt.log_analytics_workspaces : 
    {
      name = law.name
      id   = module.log_analytics_workspaces[law.name].log_analytics_workspace_id
    } 
  ]
  tags = local.globals.tags
}

module "log_analytics_workspaces" {
  source   = "github.com/JeffsterUk/Terraform_Modules/Modules/azurerm_log_analytics_workspace"
  for_each = { for law in local.mgt.log_analytics_workspaces : law.name => law }

  name                = each.value.name
  location            = local.globals.location
  resource_group_name = module.resource_groups[each.value.resource_group_name].name
  sku                 = each.value.sku
  retention_in_days   = each.value.retention_in_days
  # azure_monitor_private_link_scope = {
  #   resource_group_name = module.azure_monitor_private_link_scope.resource_group_name
  #   scope_name          = module.azure_monitor_private_link_scope.name
  # }
  tags = local.globals.tags
}