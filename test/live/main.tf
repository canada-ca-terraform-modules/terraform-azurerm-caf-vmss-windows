# No-op touch: satisfies live-test.yml's pull_request path filter (test/live/**)
# for the workflow-only PR that adds this file to CI. Re-touched to
# re-trigger a fresh live-test run after the Gen2-image fixture fix landed
# on main (PR #5) - merging that fix was a push event, not a pull_request
# event, so it didn't auto-trigger live-test on its own.
terraform {
  required_version = ">= 1.9"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0"
    }
  }

  # Empty on purpose: the state file path is supplied at `terraform init`
  # time via `-backend-config="path=..."` (partial configuration), so the
  # target-branch checkout and the PR-branch checkout can point at the same
  # external state file without either owning its own local state.
  backend "local" {}
}

provider "azurerm" {
  storage_use_azuread             = true
  resource_provider_registrations = "legacy"
  features {}
}

module "vmss_windows" {
  # PR code and baseline code are two on-disk checkouts of this same repo,
  # not two resolved git refs - no pinned ?ref, no version toggle here.
  source = "../../"

  tags            = var.tags
  env             = var.env
  location        = var.location
  resource_groups = local.resource_groups # from test_dependencies.tf
  subnets         = local.subnets         # from test_dependencies.tf
  admin_password  = var.admin_password
  vmss            = var.vmss
}
