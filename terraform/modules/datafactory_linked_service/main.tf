terraform {
  required_version = ">= 1.0.0"
}

variable "subscription_id" {
  type = string
}

variable "name" {
  type = string
}

variable "datafactory_name" {
  type = string
}

variable "resource_group" {
  type = string
}

variable "endpoint" {
  type = string
}

resource "null_resource" "linked_service" {
  triggers = {
    subscription_id  = var.subscription_id
    name             = var.name
    datafactory_name = var.datafactory_name
    resource_group   = var.resource_group
    endpoint         = var.endpoint
  }

  provisioner "local-exec" {
    when = create
    command = join(" ", [
      "bash",
      "${path.module}/update_linked_service.sh",
      self.triggers.subscription_id,
      "add",
      self.triggers.name,
      self.triggers.datafactory_name,
      self.triggers.resource_group,
      self.triggers.endpoint
    ])
  }

  provisioner "local-exec" {
    when = destroy
    command = join(" ", [
      "bash",
      "${path.module}/update_linked_service.sh",
      self.triggers.subscription_id,
      "remove",
      self.triggers.name,
      self.triggers.datafactory_name,
      self.triggers.resource_group,
      self.triggers.endpoint
    ])
  }
}

output "linked_service_name" {
  value = null_resource.linked_service.triggers.name
}
