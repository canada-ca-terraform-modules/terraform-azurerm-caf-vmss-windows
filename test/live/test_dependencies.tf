# test_dependencies.tf
# Self-contained dependency resources, owned entirely by this harness.
#
# Deliberately NOT reusing any shared/production resource group or upstream
# resource: writing into a shared RG usually requires elevated, non-sandbox
# permissions. A dedicated throwaway RG + vnet + subnet here needs only
# Contributor on the sandbox subscription and can never collide with or
# affect any production resource.
#
# terraform-azurerm-caf-vmss-windows needs a resource group (keyed map,
# var.resource_groups) and a subnet (keyed map, var.subnets) - it doesn't
# consume a vnet directly, but the subnet has to live in one.

resource "azurerm_resource_group" "live_test" {
  # PR-number suffix keeps two concurrently open PRs against this module from
  # colliding on the same sandbox resource group.
  name     = "${var.env}-caf-vmss-windows-live-test-${var.pr_number}-rg"
  location = var.location

  # pr-number tag: lets an orphan sweeper find this RG by tag and match it
  # back to a PR, independent of naming convention.
  tags = merge(var.tags, { "pr-number" = var.pr_number })
}

resource "azurerm_virtual_network" "live_test" {
  name                = "${var.env}-caf-vmss-windows-live-test-${var.pr_number}-vnet"
  address_space       = ["10.250.0.0/16"] # arbitrary, unpeered - collision-safe by construction
  location            = azurerm_resource_group.live_test.location
  resource_group_name = azurerm_resource_group.live_test.name
  tags                = var.tags
}

resource "azurerm_subnet" "live_test" {
  name                 = "live-test-snet"
  resource_group_name  = azurerm_resource_group.live_test.name
  virtual_network_name = azurerm_virtual_network.live_test.name
  address_prefixes     = ["10.250.1.0/24"]
}

locals {
  # Keyed maps matching terraform-azurerm-caf-vmss-windows's expected shape:
  # var.resource_groups[var.vmss.resource_group_name].name
  # var.subnets[var.vmss.subnet_name].id
  resource_groups = { livetest = { name = azurerm_resource_group.live_test.name } }
  subnets         = { livetest = { id = azurerm_subnet.live_test.id } }
}
