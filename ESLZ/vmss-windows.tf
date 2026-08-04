# ESLZ/vmss-windows.tf
# Declares the variables consumed by the module block so callers can wire
# their own var.* values in, and the module block itself.
# This is the file L2 callers copy into their blueprint.

terraform {
  required_version = ">= 1.9"
}

variable "vmss_windows" {
  description = "Map of Windows VMSS configuration objects"
  type        = any
  default     = {}
}

variable "resource_groups" {
  description = "Map of resource group objects"
  type        = any
  default     = {}
}

variable "subnets" {
  description = "Map of subnet objects"
  type        = any
  default     = {}
}

variable "tags" {
  description = "Tags that will be associated with the resource"
  type        = map(string)
  default     = {}
}

variable "env" {
  description = "4 characters defining the environment name prefix for the scale set"
  type        = string
}

variable "location" {
  description = "Azure location in which the scale set is deployed"
  type        = string
}

variable "admin_password" {
  description = "The password for the local administrator account on the virtual machine"
  type        = string
  sensitive   = true
}

variable "custom_data" {
  description = "Specifies custom data to supply to the VM Scale set"
  type        = string
  default     = null
}

module "vmss_windows" {
  source   = "github.com/canada-ca-terraform-modules/terraform-azurerm-caf-vmss-windows?ref=v1.3.0"
  for_each = var.vmss_windows

  tags            = var.tags
  env             = var.env
  location        = var.location
  resource_groups = var.resource_groups
  subnets         = var.subnets
  admin_password  = var.admin_password
  custom_data     = try(each.value.custom_data, var.custom_data)
  vmss            = each.value
}
