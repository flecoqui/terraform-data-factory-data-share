provider "azurerm" {
  features {}
}

locals {
  default_tags = {
    env     = var.environment
    project = var.prefix
  }
}

resource "azurerm_resource_group" "main" {
  name = join("-", flatten([
    var.prefix,
    var.environment,
    "rg"
  ]))
  location = var.location
  tags     = local.default_tags
}

resource "azurerm_data_share_account" "main" {
  name = join("-", flatten([
    var.prefix,
    var.environment,
    "dsa",
  ]))
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  identity {
    type = "SystemAssigned"
  }
  tags = local.default_tags
}

resource "azurerm_storage_account" "main" {
  name = substr(join("", flatten([
    var.prefix,
    var.environment,
    "sa",
  ])), 0, 24)
  resource_group_name       = azurerm_resource_group.main.name
  location                  = azurerm_resource_group.main.location
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  enable_https_traffic_only = true
  tags                      = local.default_tags
  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_storage_container" "provider" {
  name                  = "share-provider"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}
resource "azurerm_storage_container" "consumer" {
  name                  = "share-consumer"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

resource "azurerm_role_assignment" "provider" {
  scope                = azurerm_storage_container.provider.resource_manager_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_data_share_account.main.identity[0].principal_id
}

resource "azurerm_role_assignment" "consumer" {
  scope                = azurerm_storage_container.consumer.resource_manager_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_data_share_account.main.identity[0].principal_id
}
