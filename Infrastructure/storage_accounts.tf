module "storage_accounts" {
  source    = "../../Terraform_Modules/Modules/azure_storage_account"
  providers = { azurerm.hub_subscription = azurerm }
  for_each  = { for storage_account in concat(local.hub.storage_accounts, local.mgt.storage_accounts) : storage_account.name => storage_account }

  name                            = each.key
  resource_group_name             = module.resource_groups[each.value.resource_group_name].name
  location                        = local.globals.location
  hns_enabled                     = try(each.value.hns_enabled, false)
  allow_nested_items_to_be_public = try(each.value.allow_nested_items_to_be_public, false)
  public_network_access_enabled   = try(each.value.public_network_access_enabled, false)
  network_rules                   = each.value.network_rules
  private_endpoints = [
    {
      name      = "${each.key}-pe-001"
      subnet_id = module.subnets[each.value.private_endpoint_subnet].subnet_id
      private_service_connection = {
        name              = "${each.key}-psc-001"
        subresource_names = ["blob"]
      }
      private_dns_zone_group = {
        name                 = local.dns_map["blob"]
        private_dns_zone_ids = [module.private_dns_zones[local.dns_map["blob"]].id]
      }
    }
  ]
  # diagnostic_settings = {
  #   name = string
  #   log_analytics_workspace_id = string
  # }

  tags       = local.globals.tags
  depends_on = [module.virtual_network_peering]
}