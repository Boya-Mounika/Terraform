# Configure Azure provider
provider "azurerm" {
  features {}
}

# Create a Resource Group
# The storage account will be created inside this resource group
resource "azurerm_resource_group" "rg" {
  name     = "rg-dev"
  location = "East US"
}

# Create an Azure Storage Account
resource "azurerm_storage_account" "storage" {
  name = "mounikadevstorage2026"

  # Resource group where the storage account will be created
  resource_group_name = azurerm_resource_group.rg.name

  # Azure region
  location = azurerm_resource_group.rg.location

  # Standard performance tier
  account_tier = "Standard"

  # Locally Redundant Storage
  # Keeps multiple copies within the same Azure region
  account_replication_type = "LRS"

  # Allow only TLS 1.2 or higher
  min_tls_version = "TLS1_2"

  # Allow only HTTPS traffic
  https_traffic_only_enabled = true
}

# Create a Blob Container
# The container is created inside the storage account
resource "azurerm_storage_container" "container" {
  name = "app-data"

  # Reference the storage account
  # This creates an implicit dependency
  storage_account_id = azurerm_storage_account.storage.id

  # Keep the container private
  container_access_type = "private"
}
