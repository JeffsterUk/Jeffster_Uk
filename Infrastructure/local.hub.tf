locals {
  hub = {
    resource_groups = [
      "jfstr-hub-network-uks-rg",
      "jfstr-hub-privatedns-uks-rg"      
    ]

    network_security_groups = [
      {
        name                = "jfstr-hub-default-uks-nsg-001"
        resource_group_name = "jfstr-hub-network-uks-rg"
        rules = []
      },
      {
        name                = "jfstr-hub-appgw-uks-nsg-001"
        resource_group_name = "jfstr-hub-network-uks-rg"
        rules               = []
      }
    ]

    route_tables = [
      {
        name                = "jfstr-hub-default-uks-rt-001"
        resource_group_name = "jfstr-hub-network-uks-rg"
        routes              = []
      }
    ]

    virtual_networks = [
      {
        name                = "jfstr-hub-core-uks-vnet-001"
        resource_group_name = "jfstr-hub-network-uks-rg"
        address_space       = ["10.0.0.0/16"]
        dns_servers         = []
        subnets = [
          {
            name                   = "private-endpoints-snet"
            address_prefixes       = ["10.0.1.0/24"]
            network_security_group = "jfstr-hub-default-uks-nsg-001"
            route_table            = "jfstr-hub-default-uks-rt-001"
          },
          {
            name                   = "appgw-snet"
            address_prefixes       = ["10.0.2.0/24"]
            network_security_group = "jfstr-hub-appgw-uks-nsg-001"
            route_table            = "jfstr-hub-default-uks-rt-001"
          }
        ]
      }
    ]

    virtual_network_peerings = [
      {
        id                                        = "HUB_TO_MGT_CORE"
        spoke_allow_forwarded_traffic             = true
        spoke_allow_gateway_transit               = false
        spoke_allow_virtual_network_access        = true
        spoke_use_remote_gateways                 = false
        spoke_virtual_network_resource_group_name = "jfstr-mgt-network-uks-rg"
        spoke_virtual_network_name                = "jfstr-mgt-core-uks-vnet-001"
        hub_allow_forwarded_traffic               = false
        hub_allow_gateway_transit                 = true
        hub_allow_virtual_network_access          = true
        hub_use_remote_gateways                   = false
        hub_subscription_id                       = "87f34df8-a283-4f56-bc04-6a5e214d516d"
        hub_virtual_network_resource_group_name   = "jfstr-hub-network-uks-rg"
        hub_virtual_network_name                  = "jfstr-hub-core-uks-vnet-001"
      }
    ]

    private_dns = {
      resource_group_name = "jfstr-hub-privatedns-uks-rg"
      virtual_network_links = [
        {
          name                = "jfstr-hub-core-uks-vnet-001"
          resource_group_name = "jfstr-hub-network-uks-rg"
        }
      ]
      zones = [
      "privatelink.jeffster.uk",
      "privatelink.monitor.azure.com",
      "privatelink.oms.opinsights.azure.com",
      "privatelink.ods.opinsights.azure.com",
      "privatelink.agentsvc.azure-automation.net",
      "privatelink.blob.core.windows.net",
      "privatelink.vaultcore.azure.net",
      "privatelink.queue.core.windows.net",
      "privatelink.table.core.windows.net",
      "privatelink.file.core.windows.net"
      ]
    }

    storage_accounts = []
  }
}
