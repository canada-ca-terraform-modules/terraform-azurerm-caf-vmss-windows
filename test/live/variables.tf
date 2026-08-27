variable "env" {
  description = "4 characters defining the environment name prefix for the scale set"
  type        = string
  default     = "ltst"
}

variable "location" {
  description = "Location for the throwaway live-test resource group (+ vnet/subnet)"
  type        = string
  default     = "canadacentral"
}

variable "tags" {
  description = "Tags applied to the resources created by this harness"
  type        = map(string)
  default = {
    purpose = "module-live-test"
  }
}

variable "pr_number" {
  description = <<-EOT
    Suffix applied to test_dependencies.tf resource names so concurrent PRs
    against this module never collide on the same sandbox subscription. CI
    sources this from `TF_VAR_pr_number` (`github.event.number`); manual runs
    can leave the default or pass their own value.
  EOT
  type        = string
  default     = "manual"
}

variable "admin_password" {
  description = "Admin password for the live-test VMSS instances (CHANGE-ME placeholder in tfvars, never a real secret)"
  type        = string
  sensitive   = true
}

variable "vmss" {
  description = "Map of vmss-windows configuration objects, passed straight through to the module under test"
  type        = any
}
