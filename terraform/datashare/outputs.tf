output "datashare_resource_group_name" {
  value = module.datashare.datashare_resource_group_name
}
output "datashare_name" {
  value = module.datashare.datashare_account.name
}
output "datashare_storage_name" {
  value = module.datashare.storage_account.name
}
output "datashare_storage_container_provider_name" {
  value = module.datashare.storage_account.storage_containers.provider.name
}
output "datashare_storage_container_consumer_name" {
  value = module.datashare.storage_account.storage_containers.consumer.name
}