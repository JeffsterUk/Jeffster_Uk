module "storage_accounts" {
  source    = "../../Terraform_Modules/Modules/azurerm_storage_account"
  providers = { azurerm.hub_subscription = azurerm }
  for_each  = { for storage_account in concat( local.hub.storage_accounts, local.mgt.storage_accounts ) : storage_account.name => storage_account }

  name                            = each.key
  resource_group_name             = module.resource_groups[each.value.resource_group_name].name
  location                        = local.globals.location
  hns_enabled                     = try(each.value.hns_enabled, false)
  storage_shares                  = []
  public_network_access_enabled   = try(each.value.public_network_access_enabled, false)
  allow_nested_items_to_be_public = try(each.value.allow_nested_items_to_be_public, false)
  network_rules                   = each.value.network_rules
  log_analytics_workspace_id      = null
  enable_diagnostic_settings      = false
  private_endpoints = [
    {
      name                                 = "${each.key}-pe-001"
      private_service_connection_name      = "${each.key}-psc-001"
      subnet_id                            = module.subnets[each.value.private_endpoint_subnet].subnet_id
      subresource_names                    = [ "blob" ]
      private_dns_zone_name                = local.dns_map[ "blob" ]
      private_dns_zone_resource_group_name = local.hub.private_dns.resource_group_name
      is_manual_connection                 = false
    },
    {
      name                                 = "${each.key}-pe-002"
      private_service_connection_name      = "${each.key}-psc-001"
      subnet_id                            = module.subnets[each.value.private_endpoint_subnet].subnet_id
      subresource_names                    = [ "file" ]
      private_dns_zone_name                = local.dns_map[ "file" ]
      private_dns_zone_resource_group_name = local.hub.private_dns.resource_group_name
      is_manual_connection                 = false
    },
    {
      name                                 = "${each.key}-pe-003"
      private_service_connection_name      = "${each.key}-psc-001"
      subnet_id                            = module.subnets[each.value.private_endpoint_subnet].subnet_id
      subresource_names                    = [ "queue" ]
      private_dns_zone_name                = local.dns_map[ "queue" ]
      private_dns_zone_resource_group_name = local.hub.private_dns.resource_group_name
      is_manual_connection                 = false
    },
    {
      name                                 = "${each.key}-pe-004"
      private_service_connection_name      = "${each.key}-psc-001"
      subnet_id                            = module.subnets[each.value.private_endpoint_subnet].subnet_id
      subresource_names                    = [ "table" ]
      private_dns_zone_name                = local.dns_map[ "table" ]
      private_dns_zone_resource_group_name = local.hub.private_dns.resource_group_name
      is_manual_connection                 = false
    }
  ]
  tags       = local.globals.tags
  depends_on = [ module.virtual_network_peering ]
}