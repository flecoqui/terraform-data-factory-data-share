variable "prefix" {
  type        = string
  description = "Prefix used to provide a name to the Azure resources"
  default     = "testdf"
}
variable "location" {
  type        = string
  description = "Azure region where the Azure resources will be deployed"
  default     = "eastus2"
}
variable "environment" {
  type        = string
  description = "Deployment environment for instance: dev, prod, stagind, test, ..."
  default     = "dev"
}
