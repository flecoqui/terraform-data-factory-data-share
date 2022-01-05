provider "azurerm" {
  features {}
}

terraform {
  backend "azurerm" {}
  required_providers {
    azurerm = {
      source  = "azurerm"
      version = "~> 2.0"
    }
  }
}

module "datashare" {
  source      = "../modules/datashare"
  prefix      = var.prefix
  location    = var.location
  environment = var.environment
}
