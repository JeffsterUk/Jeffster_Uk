locals {
  all = {
    resource_groups = concat(
      local.hub.resource_groups,
      local.mgt.resource_groups
    )

    virtual_networks = concat(
      local.hub.virtual_networks,
      local.mgt.virtual_networks
    )

    virtual_network_peerings = concat(
      local.hub.virtual_network_peerings
    )

    network_security_groups = concat(
      local.hub.network_security_groups,
      local.mgt.network_security_groups
    )

    route_tables = concat(
      local.hub.route_tables,
      local.mgt.route_tables
    )

    private_dns_zones = concat(
      local.hub.private_dns_zones
    )

    log_analytics_workspaces = concat(
      local.mgt.log_analytics_workspaces
    )
  }

  mgt = {
    resource_groups = [
      "${local.globals.company_prefix}-${local.globals.environment}-MGT-CORE-NETWORK-UKS-RG",
      "${local.globals.company_prefix}-${local.globals.environment}-MGT-LOG-NETWORK-UKS-RG"
    ]

    virtual_networks = [
      {
        name                = "${local.globals.company_prefix}-${local.globals.environment}-MGT-CORE-UKS-VNET-001"
        resource_group_name = "${local.globals.company_prefix}-${local.globals.environment}-MGT-CORE-NETWORK-UKS-RG"
        address_space       = ["10.1.0.0/16"]
        dns_servers         = []
        subnets = [
          {
            name                   = "PRIVATE-ENDPOINTS-SNET"
            address_prefixes       = ["10.1.1.0/24"]
            network_security_group = "${local.globals.company_prefix}-${local.globals.environment}-MGT-CORE-UKS-NSG-001"
            route_table            = "${local.globals.company_prefix}-${local.globals.environment}-MGT-CORE-UKS-RT-001"
          },
          {
            name                   = "API-MGT-SNET"
            address_prefixes       = ["10.1.2.0/24"]
            network_security_group = "${local.globals.company_prefix}-${local.globals.environment}-MGT-APIMGT-UKS-NSG-001"
            route_table            = "${local.globals.company_prefix}-${local.globals.environment}-MGT-CORE-UKS-RT-001"
          }
        ]
      }
    ]

    network_security_groups = [
      {
        name                = "${local.globals.company_prefix}-${local.globals.environment}-MGT-CORE-UKS-NSG-001"
        resource_group_name = "${local.globals.company_prefix}-${local.globals.environment}-MGT-CORE-NETWORK-UKS-RG"
        rules = [
          # {
          #   name                         = "ClientToAppGw"
          #   priority                     = 1001
          #   direction                    = "Inbound"
          #   access                       = "Allow"
          #   protocol                     = "Tcp"
          #   source_port_ranges           = ["*"]
          #   destination_port_ranges      = ["443"]
          #   source_address_prefixes      = ["*"]
          #   destination_address_prefixes = ["*"]
          #   resource_group_name          = "RBGKew-PROD-Hubnet-UKS-RG"
          #   network_security_group_name  = "RBGKew-PROD-Hubnet-DMZ-UKS-NSG-001"
          # }
        ]
      },
      {
        name                = "${local.globals.company_prefix}-${local.globals.environment}-MGT-APIMGT-UKS-NSG-001"
        resource_group_name = "${local.globals.company_prefix}-${local.globals.environment}-MGT-CORE-NETWORK-UKS-RG"
        rules = [
          # {
          #   name                         = "ClientToAppGw"
          #   priority                     = 1001
          #   direction                    = "Inbound"
          #   access                       = "Allow"
          #   protocol                     = "Tcp"
          #   source_port_ranges           = ["*"]
          #   destination_port_ranges      = ["443"]
          #   source_address_prefixes      = ["*"]
          #   destination_address_prefixes = ["*"]
          #   resource_group_name          = "RBGKew-PROD-Hubnet-UKS-RG"
          #   network_security_group_name  = "RBGKew-PROD-Hubnet-DMZ-UKS-NSG-001"
          # }
        ]
      }
    ]

    route_tables = [
      {
        name                = "${local.globals.company_prefix}-${local.globals.environment}-MGT-CORE-UKS-RT-001"
        resource_group_name = "${local.globals.company_prefix}-${local.globals.environment}-MGT-CORE-NETWORK-UKS-RG"
        routes              = []
      }
    ]

    log_analytics_workspaces = [
      {
        name                = "${local.globals.company_prefix}-${local.globals.environment}-MGT-LOG-NETWORK-UKS-LOG"
        resource_group_name = "${local.globals.company_prefix}-${local.globals.environment}-MGT-LOG-NETWORK-UKS-RG"
        sku                 = "PerGB2018"
        retention_in_days   = 30
      }
    ]
  }

  hub = {
    resource_groups = [
      "${local.globals.company_prefix}-${local.globals.environment}-HUB-CORE-NETWORK-UKS-RG"
    ]

    virtual_networks = [
      {
        name                = "${local.globals.company_prefix}-${local.globals.environment}-HUB-CORE-UKS-VNET-001"
        resource_group_name = "${local.globals.company_prefix}-${local.globals.environment}-HUB-CORE-NETWORK-UKS-RG"
        address_space       = ["10.0.0.0/16"]
        dns_servers         = []
        subnets = [
          {
            name                   = "PRIVATE-ENDPOINTS-SNET"
            address_prefixes       = ["10.0.1.0/24"]
            network_security_group = "${local.globals.company_prefix}-${local.globals.environment}-HUB-CORE-UKS-NSG-001"
            route_table            = "${local.globals.company_prefix}-${local.globals.environment}-HUB-CORE-UKS-RT-001"
          },
          {
            name                   = "APP-GW-SNET"
            address_prefixes       = ["10.0.2.0/24"]
            network_security_group = "${local.globals.company_prefix}-${local.globals.environment}-HUB-APPGW-UKS-NSG-001"
            route_table            = "${local.globals.company_prefix}-${local.globals.environment}-HUB-CORE-UKS-RT-001"
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
        spoke_virtual_network_resource_group_name = "${local.globals.company_prefix}-${local.globals.environment}-MGT-CORE-NETWORK-UKS-RG"
        spoke_virtual_network_name                = "${local.globals.company_prefix}-${local.globals.environment}-MGT-CORE-UKS-VNET-001"
        hub_allow_forwarded_traffic               = false
        hub_allow_gateway_transit                 = true
        hub_allow_virtual_network_access          = true
        hub_use_remote_gateways                   = false
        hub_subscription_id                       = "87f34df8-a283-4f56-bc04-6a5e214d516d"
        hub_virtual_network_resource_group_name   = "${local.globals.company_prefix}-${local.globals.environment}-HUB-CORE-NETWORK-UKS-RG"
        hub_virtual_network_name                  = "${local.globals.company_prefix}-${local.globals.environment}-HUB-CORE-UKS-VNET-001"
      }
    ]

    network_security_groups = [
      {
        name                = "${local.globals.company_prefix}-${local.globals.environment}-HUB-CORE-UKS-NSG-001"
        resource_group_name = "${local.globals.company_prefix}-${local.globals.environment}-HUB-CORE-NETWORK-UKS-RG"
        rules = [
          # {
          #   name                         = "ClientToAppGw"
          #   priority                     = 1001
          #   direction                    = "Inbound"
          #   access                       = "Allow"
          #   protocol                     = "Tcp"
          #   source_port_ranges           = ["*"]
          #   destination_port_ranges      = ["443"]
          #   source_address_prefixes      = ["*"]
          #   destination_address_prefixes = ["*"]
          #   resource_group_name          = "RBGKew-PROD-Hubnet-UKS-RG"
          #   network_security_group_name  = "RBGKew-PROD-Hubnet-DMZ-UKS-NSG-001"
          # }
        ]
      },
      {
        name                = "${local.globals.company_prefix}-${local.globals.environment}-HUB-APPGW-UKS-NSG-001"
        resource_group_name = "${local.globals.company_prefix}-${local.globals.environment}-HUB-CORE-NETWORK-UKS-RG"
        rules               = []
      }
    ]

    route_tables = [
      {
        name                = "${local.globals.company_prefix}-${local.globals.environment}-HUB-CORE-UKS-RT-001"
        resource_group_name = "${local.globals.company_prefix}-${local.globals.environment}-HUB-CORE-NETWORK-UKS-RG"
        routes              = []
      }
    ]

    private_dns_zones = [
      "privatelink.jeffster.uk",
      "privatelink.monitor.azure.com",
      "privatelink.oms.opinsights.azure.com",
      "privatelink.ods.opinsights.azure.com",
      "privatelink.agentsvc.azure-automation.net",
      "privatelink.blob.core.windows.net",
      "privatelink.vaultcore.azure.net"
    ]
  }
}