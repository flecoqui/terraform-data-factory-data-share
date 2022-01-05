output "datafactory_resource_group_name" {
  value = module.datafactory.datafactory_resource_group_name
}
output "datafactory_name" {
  value = module.datafactory.datafactory_account.name
}
output "datafactory_storage_name" {
  value = module.datafactory.storage_account.name
}
output "datafactory_storage_container_input_name" {
  value = module.datafactory.storage_account.storage_containers.input.name
}
output "datafactory_storage_container_output_name" {
  value = module.datafactory.storage_account.storage_containers.output.name
}
output "output_linked_service_name" {
  value = module.datafactory.output_linked_service_name
}
output "input_linked_service_name" {
  value = module.datafactory.input_linked_service_name
}