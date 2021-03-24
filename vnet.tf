# Virtual network
resource "azurerm_virtual_network" "vnet" {
  name                = join("", [var.application,var.environment,"vnet"])
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]

  tags = {
    application = var.application
    environment = var.environment
    component = "VNET"
  }
}

# Subnets
resource "azurerm_subnet" "dbsubnet" {
    name             = "DatabaseSubnet"
    resource_group_name = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes = ["10.0.1.0/24"]
    service_endpoints = ["Microsoft.Sql"]
    enforce_private_link_endpoint_network_policies = true
}

resource "azurerm_subnet" "vmsubnet" {
    name           = "VMSubnet"
    resource_group_name = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes = ["10.0.2.0/24"]
}

# Private endpoint for SQL DB
resource "azurerm_private_dns_zone" "pvtdnszone" {
  name                = "privatelink.database.windows.net"
  resource_group_name = azurerm_resource_group.rg.name

  tags = {
    application = var.application
    environment = var.environment
    component = "VNET"
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "dnszonelnk" {
  name                  = join("", [var.application,var.environment,"dnslnk"])
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.pvtdnszone.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

resource "azurerm_private_endpoint" "sqlpvtep" {
  name                = join("", [var.application,var.environment,"pvtep"])
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.dbsubnet.id

  private_dns_zone_group {
    name = join("", [var.application,var.environment,"pvtdnszone"])
    private_dns_zone_ids = [azurerm_private_dns_zone.pvtdnszone.id]
  }

  private_service_connection {
    name                           = join("", [var.application,var.environment,"-pvtsvcconn"])
    private_connection_resource_id = azurerm_sql_server.sqlsvr.id
    subresource_names = [ "sqlServer" ]
    is_manual_connection = false
  }

  tags = {
    application = var.application
    environment = var.environment
    component = "VNET"
  }
}