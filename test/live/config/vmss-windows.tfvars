# config/vmss-windows.tfvars
# Tracked, ready-to-run fixture for the test/live harness - adapted from the
# L2_test_vmss-windows upgrade-probe harness fixture
# (G1Sc-CTO-ENT-ESLZ-Modules-Testing-and-Validation).
#
# This harness deploys into its own throwaway resource group + vnet + subnet
# (see test_dependencies.tf) - no shared resource group permissions needed,
# and no risk of colliding with any real resource.
#
# admin_password: obvious CHANGE-ME placeholder - a real secret must never be
# committed. This is a literal string, not a generated value, because the
# module's azurerm_windows_virtual_machine_scale_set.admin_password argument
# would otherwise be unknown-until-apply and could break count/for_each
# expressions that depend on it during the very first plan.
admin_password = "CHANGE-ME-P@ssw0rd1234!"

vmss = {
  resource_group_name = "livetest"
  subnet_name         = "livetest"
  # Dav6 family: the sandbox subscription's default Dsv5/Dasv5 family quota
  # in canadacentral hits a hard Azure capacity restriction. Dav6 quota has
  # been provisioned specifically to avoid this - do not switch families.
  sku                    = "Standard_D2as_v6"
  instances              = 1
  postfix                = "lts"
  userDefinedString      = "livetest"
  overprovision          = true
  single_placement_group = true

  source_image_reference = {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    # -g2 (Gen2) image SKU: required to boot Dav6-family VM sizes
    # (Standard_D2as_v6 et al. are Gen2-only; the non-suffixed
    # "2022-Datacenter" SKU is Gen1 and 400s with "cannot boot Hypervisor
    # Generation '1'" against this family).
    sku     = "2022-datacenter-g2"
    version = "latest"
  }

  os_disk = {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  # Exercises the loadbalancer.tf resources (azurerm_lb, azurerm_lb_probe,
  # azurerm_lb_backend_address_pool, azurerm_lb_rule).
  lb = {
    private_ip_address_allocation = "Dynamic"
    probes = {
      tcp443 = { port = 443 }
    }
    rules = {
      tcp443 = {
        protocol            = "Tcp"
        frontend_port       = 443
        backend_port        = 443
        probe_name          = "tcp443"
        load_distribution   = "SourceIPProtocol"
        floating_ip_enabled = true
      }
    }
  }
}
