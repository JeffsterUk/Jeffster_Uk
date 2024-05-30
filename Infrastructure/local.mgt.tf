locals {
  mgt = {
    resource_groups = [
      "jfstr-mgt-network-uks-rg",
      "jfstr-mgt-log-uks-rg",
      "jfstr-mgt-terraform-uks-rg",
      "jfstr-mgt-tempdeploy-uks-rg"
    ]

    network_security_groups = [
      {
        name                = "jfstr-mgt-default-uks-nsg-001"
        resource_group_name = "jfstr-mgt-network-uks-rg"
        rules               = []
      },
      {
        name                = "jfstr-mgt-apim-uks-nsg-001"
        resource_group_name = "jfstr-mgt-network-uks-rg"
        rules = [
          {
            name                         = "in-apim-3443"
            description                  = "Management endpoint for Azure portal and PowerShell"
            priority                     = 100
            direction                    = "Inbound"
            protocol                     = "Tcp"
            source_port_ranges           = ["*"]
            destination_port_ranges      = ["3443"]
            source_address_prefixes      = ["ApiManagement"]
            destination_address_prefixes = ["VirtualNetwork"]
          },
          {
            name                         = "in-apim-loadbalancer-6390"
            description                  = "Azure Infrastructure Load Balancer"
            priority                     = 200
            direction                    = "Inbound"
            protocol                     = "Tcp"
            source_port_ranges           = ["*"]
            destination_port_ranges      = ["6390"]
            source_address_prefixes      = ["AzureLoadBalancer"]
            destination_address_prefixes = ["VirtualNetwork"]
          },
          {
            name                         = "out-apim-storage-443"
            description                  = "Dependency on Azure Storage for core service functionality"
            priority                     = 100
            direction                    = "Outbound"
            protocol                     = "Tcp"
            source_port_ranges           = ["*"]
            destination_port_ranges      = ["443"]
            source_address_prefixes      = ["VirtualNetwork"]
            destination_address_prefixes = ["Storage"]
          },
          {
            name                         = "out-apim-sql-1433"
            description                  = "Access to Azure SQL endpoints for core service functionality"
            priority                     = 200
            direction                    = "Outbound"
            protocol                     = "Tcp"
            source_port_ranges           = ["*"]
            destination_port_ranges      = ["1433"]
            source_address_prefixes      = ["VirtualNetwork"]
            destination_address_prefixes = ["SQL"]

          },
          {
            name                         = "out-apim-keyvault-443"
            description                  = "Access to Azure Key Vault for core service functionality"
            priority                     = 300
            direction                    = "Outbound"
            protocol                     = "Tcp"
            source_port_ranges           = ["*"]
            destination_port_ranges      = ["443"]
            source_address_prefixes      = ["VirtualNetwork"]
            destination_address_prefixes = ["AzureKeyVault"]

          },
          {
            name                         = "out-apim-azuremonitor-1886-443"
            description                  = "Publish Diagnostics Logs and Metrics, Resource Health, and Application Insights"
            priority                     = 400
            direction                    = "Outbound"
            protocol                     = "Tcp"
            source_port_ranges           = ["*"]
            destination_port_ranges      = ["1886", "443"]
            source_address_prefixes      = ["VirtualNetwork"]
            destination_address_prefixes = ["AzureMonitor"]

          }
        ]
      }
    ]

    route_tables = [
      {
        name                = "jfstr-mgt-default-uks-rt-001"
        resource_group_name = "jfstr-mgt-network-uks-rg"
        routes              = []
      }
    ]

    virtual_networks = [
      {
        name                = "jfstr-mgt-core-uks-vnet-001"
        resource_group_name = "jfstr-mgt-network-uks-rg"
        address_space       = ["10.1.0.0/16"]
        dns_servers         = []
        subnets = [
          {
            name                   = "private-endpoints-snet"
            address_prefixes       = ["10.1.1.0/24"]
            network_security_group = "jfstr-mgt-default-uks-nsg-001"
            route_table            = "jfstr-mgt-default-uks-rt-001"
          },
          {
            name                   = "apim-snet"
            address_prefixes       = ["10.1.2.0/24"]
            network_security_group = "jfstr-mgt-apim-uks-nsg-001"
            route_table            = "jfstr-mgt-default-uks-rt-001"
          }
        ]
      }
    ]

    storage_accounts = [
      {
        name                = "jfstrmgttfstateukssa001"
        resource_group_name = "jfstr-mgt-terraform-uks-rg"
        account_tier        = "Standard"
        account_replication = "LRS"
        network_rules = {
          default_action = "Deny"
        }
        private_endpoint_subnet = "jfstr-mgt-core-uks-vnet-001\\private-endpoints-snet"
      }
    ]

    azure_monitor_private_link_scope = {
      name                = "jfstr-mgt-core-uks-ampls"
      resource_group_name = "jfstr-mgt-log-uks-rg"
      private_endpoint = {
        name                            = "jfstr-mgt-core-uks-ampls-pe-001"
        private_endpoint_subnet         = "jfstr-mgt-core-uks-vnet-001\\private-endpoints-snet"
        custom_network_interface_name   = "jfstr-mgt-core-uks-ampls-nic-001"
        private_service_connection_name = "jfstr-mgt-core-uks-psc-pe-001"
        private_dns_zones = [
          "privatelink.monitor.azure.com",
          "privatelink.oms.opinsights.azure.com",
          "privatelink.ods.opinsights.azure.com",
          "privatelink.agentsvc.azure-automation.net",
          "privatelink.blob.core.windows.net"
        ]
      }
    }

    log_analytics_workspaces = [
      {
        name                = "jfstr-mgt-diagnostics-uks-log"
        resource_group_name = "jfstr-mgt-log-uks-rg"
        sku                 = "PerGB2018"
        retention_in_days   = 30
      }
    ]
  }
}
