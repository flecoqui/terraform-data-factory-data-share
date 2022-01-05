output "datashare_resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "datashare_account" {
  value = {
    id                  = azurerm_data_share_account.main.id
    name                = azurerm_data_share_account.main.name
    resource_group_name = azurerm_data_share_account.main.resource_group_name
  }
}

output "storage_account" {
  value = {
    id                  = azurerm_storage_account.main.id
    name                = azurerm_storage_account.main.name
    resource_group_name = azurerm_storage_account.main.resource_group_name
    storage_containers = {
      provider = {
        id                  = azurerm_storage_container.provider.id
        name                = azurerm_storage_container.provider.name
        resource_manager_id = azurerm_storage_container.provider.resource_manager_id
      },
      consumer = {
        id                  = azurerm_storage_container.consumer.id
        name                = azurerm_storage_container.consumer.name
        resource_manager_id = azurerm_storage_container.consumer.resource_manager_id
      }
    }
  }
}
