# Reserve a public IP for the SQL VM
resource "azurerm_public_ip" "vmpubip" {
  name                = join("", [var.application,var.environment,"pip"])
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  domain_name_label = join("", [var.application,var.environment,"sqlvm"])

  tags = {
    application = var.application
    environment = var.environment
    component = "SQL VM"
  }
}

# Create an NSG and allow the "admin" IP access to RDP and SQL ports
resource "azurerm_network_security_group" "vmnsg" {
  name                = join("", [var.application,var.environment,"vmnsg"])
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = {
    application = var.application
    environment = var.environment
    component = "SQL VM"
  }
}

resource "azurerm_network_security_rule" "RDPRule" {
  name                        = "RDPRule"
  resource_group_name         = azurerm_resource_group.rg.name
  priority                    = 1000
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = 3389
  source_address_prefix       = var.admin_ip
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.vmnsg.name
}

resource "azurerm_network_security_rule" "MSSQLRule" {
  name                        = "MSSQLRule"
  resource_group_name         = azurerm_resource_group.rg.name
  priority                    = 1001
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = 1433
  source_address_prefix       = var.admin_ip
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.vmnsg.name
}

# Create a NIC for the SQL VM
resource "azurerm_network_interface" "vmnic" {
  name                = join("", [var.application,var.environment,"nic"])
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.vmsubnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vmpubip.id
  }

  tags = {
    application = var.application
    environment = var.environment
    component = "SQL VM"
  }
}

resource "azurerm_network_interface_security_group_association" "vmnicsg" {
  network_interface_id      = azurerm_network_interface.vmnic.id
  network_security_group_id = azurerm_network_security_group.vmnsg.id
}

# Create the virtual machine
resource "azurerm_virtual_machine" "sqlvm" {
  name                  = join("", [var.application,var.environment,"sqlvm"])
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.vmnic.id]
  vm_size               = "Standard_DS3_v2"

  storage_image_reference {
    publisher = "MicrosoftSQLServer"
    offer     = "SQL2017-WS2016"
    sku       = "SQLDEV"
    version   = "latest"
  }

  storage_os_disk {
    name              = join("", [var.application,var.environment,"-osdisk"])
    caching           = "ReadOnly"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  os_profile {
    computer_name  = join("", [var.environment,"sqlvm"])
    admin_username = var.admin_login
    admin_password = var.admin_password
  }

  os_profile_windows_config {
    timezone                  = "Eastern Standard Time"
    provision_vm_agent        = true
    enable_automatic_upgrades = true
  }

  tags = {
    application = var.application
    environment = var.environment
    component = "SQL VM"
  }  
}

# Add the SQL Server extension
resource "azurerm_mssql_virtual_machine" "sqlvm" {
  virtual_machine_id = azurerm_virtual_machine.sqlvm.id
  sql_license_type   = "PAYG"
  r_services_enabled               = true
  sql_connectivity_port            = 1433
  sql_connectivity_type            = "PRIVATE"
  sql_connectivity_update_password = var.admin_password
  sql_connectivity_update_username = var.admin_login

  auto_patching {
    day_of_week                            = "Sunday"
    maintenance_window_duration_in_minutes = 60
    maintenance_window_starting_hour       = 2
  }

  tags = {
    application = var.application
    environment = var.environment
    component = "SQL VM"
  }  
}

# Output the VM public IP address and FQDN
data "azurerm_public_ip" "vmpubip" {
  name                = azurerm_public_ip.vmpubip.name
  resource_group_name = azurerm_resource_group.rg.name
}

output "vm_public_ip_address" {
  value = data.azurerm_public_ip.vmpubip.ip_address
}

output "vm_dns_name" {
  value = data.azurerm_public_ip.vmpubip.fqdn
}
