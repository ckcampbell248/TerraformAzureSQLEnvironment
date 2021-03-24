variable "application" {
  type = string
  description = "This is the name of the application this environment belongs to."
}

variable "environment" {
  type = string
  description = "This is the envronment level (i.e. dev, test, ua, prod)"
}

variable "location" {
  type = string
  description = "Azure region for deployment"
}

variable "admin_login" {
  type = string
  description = "SQL and VM admin login"
  sensitive = true
} 

variable "admin_password" {
  type = string
  description = "SQL and VM admin password"
  sensitive = true
}

variable "database_bacpac_storage_account" {
  type = string
  description = "Storage account for database bacpac"
  sensitive = true
}

variable "database_bacpac_storage_account_rg" {
  type = string
  description = "Resource Group for storage account"
  sensitive = true
}

variable "database_bacpac_storage_blob" {
  type = string
  description = "Database bacpac to import into SQL DB"
  sensitive = true
}

variable "admin_ip" {
  type = string
  description = "Home IP address for admin"
  sensitive = true
}

variable "admin_aad" {
  type = string
  description = "Azure AD admin for SQL Server"
  sensitive = true
}
