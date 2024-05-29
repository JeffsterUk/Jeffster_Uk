locals {
  dns_map = {
    blob        = "privatelink.blob.core.windows.net"
    file        = "privatelink.file.core.windows.net"
    queue       = "privatelink.queue.core.windows.net"
    table       = "privatelink.table.core.windows.net"
    dfs         = "privatelink.dfs.core.windows.net"
    sites       = "privatelink.azurewebsites.net"
    vault       = "privatelink.vaultcore.azure.net"
    Dev         = "privatelink.dev.azuresynapse.net"
    SqlOnDemand = "privatelink.sql.azuresynapse.net"
    Sql         = "privatelink.sql.azuresynapse.net"
    namespace   = "privatelink.servicebus.windows.net"
    sqlServer   = "privatelink.database.windows.net"
  }
}