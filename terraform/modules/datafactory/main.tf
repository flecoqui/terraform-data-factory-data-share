provider "azurerm" {
  features {}
}

locals {
  default_tags = {
    env     = var.environment
    project = var.prefix
  }
}

data "azurerm_subscription" "current" {
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

resource "azurerm_storage_container" "input" {
  name                  = "input"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "output" {
  name                  = "output"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

resource "azurerm_data_factory" "main" {
  name = join("-", flatten([
    var.prefix,
    var.environment,
    "df"
  ]))
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  identity {
    type = "SystemAssigned"
  }
}

module "output_linked_service" {
  source = "../datafactory_linked_service"

  subscription_id = data.azurerm_subscription.current.subscription_id
  name = join("-", flatten([
    "output",
    var.prefix,
    var.environment,
    "dflk",
  ]))
  datafactory_name = azurerm_data_factory.main.name
  resource_group   = azurerm_resource_group.main.name
  endpoint         = azurerm_storage_container.output.id
}

module "input_linked_service" {
  source = "../datafactory_linked_service"

  subscription_id = data.azurerm_subscription.current.subscription_id
  name = join("-", flatten([
    "input",
    var.prefix,
    var.environment,
    "dflk",
  ]))
  datafactory_name = azurerm_data_factory.main.name
  resource_group   = azurerm_resource_group.main.name
  endpoint         = azurerm_storage_container.input.id
}

resource "azurerm_role_assignment" "input" {
  scope                = azurerm_storage_container.input.resource_manager_id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_data_factory.main.identity[0].principal_id
}

resource "azurerm_role_assignment" "output" {
  scope                = azurerm_storage_container.output.resource_manager_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_data_factory.main.identity[0].principal_id
}
