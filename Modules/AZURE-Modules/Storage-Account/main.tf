#Storage Account

resource "azurerm_storage_account" "storage" {
  name                     = "mounikadevstorage01"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location

  account_tier             = "Standard"
  account_replication_type = "LRS"

  min_tls_version          = "TLS1_2"

  https_traffic_only_enabled = true
}

#Blob Container
resource "azurerm_storage_container" "container" {
  name                  = "app-data"
  storage_account_id    = azurerm_storage_account.storage.id
  container_access_type = "private"
}
