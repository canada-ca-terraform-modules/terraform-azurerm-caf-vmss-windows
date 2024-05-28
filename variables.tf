variable "tags" {
  description = "Tags that will be associated with the ressource"
  type = map(string)
}

variable "env" {
  description = "4 characters defining the environment name prefix for the scale set"
  type = string
}

variable "location" {
  description = "Azure location in which the scale set is deployed"
  type = string
}

variable "vmss" {
  description = "Details about vmss config"
  type        = any
  default     = {}
}

variable "resource_groups" {
  description = "List of resource groups objets"
  type = any
}

variable "subnets" {
  description = "List of subnets objects"
  type = any
}

variable "admin_password" {
  description = "The password for the local administrator account on the virtual machine"
  type = string
}