# Azure SQL Database Server
resource "azurerm_sql_server" "sqlsvr" {
  name                         = join("", [var.application,var.environment,"sqlsvr"])
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = var.location
  version                      = "12.0"
  administrator_login          = var.admin_login
  administrator_login_password = var.admin_password

  tags = {
    application = var.application
    environment = var.environment
    component = "SQL DB"
  }
}

# Storage account for log storage
resource "azurerm_storage_account" "logstg" {
  name                     = join("", [var.application,var.environment,"sqllogs"])
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    application = var.application
    environment = var.environment
    component = "SQL DB"
  }
}

# Logging policy for Azure SQL Server
resource "azurerm_mssql_server_extended_auditing_policy" "sqllogpolicy" {
  server_id                               = azurerm_sql_server.sqlsvr.id
  storage_endpoint                        = azurerm_storage_account.logstg.primary_blob_endpoint
  storage_account_access_key              = azurerm_storage_account.logstg.primary_access_key
  storage_account_access_key_is_secondary = false
  retention_in_days                       = 6
}

# Administrator's firewall rules
resource "azurerm_sql_firewall_rule" "rule1" {
  name                = "Allow all Azure services"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_sql_server.sqlsvr.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

resource "azurerm_sql_firewall_rule" "rule2" {
  name                = "Admin at home"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_sql_server.sqlsvr.name
  start_ip_address    = var.admin_ip
  end_ip_address      = var.admin_ip
}

# Set Azure AD admin
resource "azurerm_sql_active_directory_administrator" "sqlsvr" {
  server_name         = azurerm_sql_server.sqlsvr.name
  resource_group_name = azurerm_resource_group.rg.name
  login               = var.admin_aad
  tenant_id           = data.azurerm_client_config.current.tenant_id
  object_id           = data.azurerm_client_config.current.object_id
}

# Azure SQL Database
resource "azurerm_sql_database" "sqldb" {
  name                = join("", [var.application,var.environment,"sqldb"])
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  server_name         = azurerm_sql_server.sqlsvr.name

  import {
    storage_uri = var.database_bacpac_storage_blob
    storage_key = data.azurerm_storage_account.stg.primary_access_key
    storage_key_type = "StorageAccessKey"
    administrator_login = azurerm_sql_server.sqlsvr.administrator_login
    administrator_login_password = azurerm_sql_server.sqlsvr.administrator_login_password
    authentication_type = "SQL"
    operation_mode = "Import"
  }

  tags = {
    application = var.application
    environment = var.environment
    component = "SQL DB"
  }
}
