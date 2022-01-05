output "datafactory_resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "datafactory_account" {
  value = {
    id                  = azurerm_data_factory.main.id
    name                = azurerm_data_factory.main.name
    resource_group_name = azurerm_data_factory.main.resource_group_name
  }
}

output "storage_account" {
  value = {
    id                  = azurerm_storage_account.main.id
    name                = azurerm_storage_account.main.name
    resource_group_name = azurerm_storage_account.main.resource_group_name
    storage_containers = {
      input = {
        id                  = azurerm_storage_container.input.id
        name                = azurerm_storage_container.input.name
        resource_manager_id = azurerm_storage_container.input.resource_manager_id
      },
      output = {
        id                  = azurerm_storage_container.output.id
        name                = azurerm_storage_container.output.name
        resource_manager_id = azurerm_storage_container.output.resource_manager_id
      }
    }
  }
}

output "output_linked_service_name" {
  value = module.output_linked_service.linked_service_name
}

output "input_linked_service_name" {
  value = module.input_linked_service.linked_service_name
}