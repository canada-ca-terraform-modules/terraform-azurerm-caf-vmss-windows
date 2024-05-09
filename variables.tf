variable "tags" {
  type = any
}

variable "env" {
  type = string
}
variable "group" {
  type = string
}
variable "project" {
  type = string
}

variable "location" {
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
  type = string
}