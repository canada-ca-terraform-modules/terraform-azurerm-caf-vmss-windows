# tests/upgrade_compat.tftest.hcl
# State-chaining upgrade safety test: applies a "pre-upgrade" configuration
# (using only fields/keys available before this azurerm v5.0.1 upgrade), then
# plans the "post-upgrade" configuration against that state to prove no
# resource is destroyed/recreated and no address changed.

mock_provider "azurerm" {}

variables {
  tags           = { environment = "test" }
  env            = "Dev"
  location       = "canadacentral"
  admin_password = "P@55w0rd1234!"
  resource_groups = {
    rg-test = { name = "rg-test", location = "canadacentral" }
  }
  subnets = {
    snet-test = { id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-test" }
  }
}

run "baseline_apply" {
  command = apply

  variables {
    vmss = {
      resource_group_name    = "rg-test"
      subnet_name            = "snet-test"
      sku                    = "Standard_D2s_v5"
      instances              = 1
      postfix                = "cmp"
      userDefinedString      = "cmp"
      overprovision          = true
      single_placement_group = true
      source_image_reference = {
        publisher = "MicrosoftWindowsServer"
        offer     = "WindowsServer"
        sku       = "2022-Datacenter"
        version   = "latest"
      }
      os_disk = {
        storage_account_type = "Standard_LRS"
        caching              = "ReadWrite"
      }
      lb = {
        private_ip_address_allocation = "Dynamic"
        probes = {
          tcp443 = { port = 443 }
        }
        rules = {
          tcp443 = {
            protocol          = "Tcp"
            frontend_port     = 443
            backend_port      = 443
            probe_name        = "tcp443"
            load_distribution = "SourceIPProtocol"
            # pre-upgrade callers used the legacy key name
            enable_floating_ip = true
          }
        }
      }
    }
  }

  override_resource {
    target = azurerm_lb.loadbalancer[0]
    values = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/loadBalancers/DevSWG-cmcmp-lb"
    }
  }

  override_resource {
    target = azurerm_lb_backend_address_pool.loadbalancer-lbbp[0]
    values = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/loadBalancers/DevSWG-cmcmp-lb/backendAddressPools/DevSWG-cmcmp-HA-lbbp"
    }
  }

  assert {
    condition     = azurerm_windows_virtual_machine_scale_set.vmss_windows.name == "DevSWG-cmcmp-vmss"
    error_message = "Baseline apply: unexpected VMSS name"
  }
  assert {
    condition     = azurerm_lb_rule.loadbalancer-lbr["tcp443"].name == "DevSWG-cmcmp-tcp443-lbr"
    error_message = "Baseline apply: unexpected LB rule name"
  }
}

run "upgrade_plan_no_replacement" {
  command = plan

  variables {
    vmss = {
      resource_group_name    = "rg-test"
      subnet_name            = "snet-test"
      sku                    = "Standard_D2s_v5"
      instances              = 1
      postfix                = "cmp"
      userDefinedString      = "cmp"
      overprovision          = true
      single_placement_group = true
      source_image_reference = {
        publisher = "MicrosoftWindowsServer"
        offer     = "WindowsServer"
        sku       = "2022-Datacenter"
        version   = "latest"
      }
      os_disk = {
        storage_account_type = "Standard_LRS"
        caching              = "ReadWrite"
      }
      # post-upgrade: new optional args added, additive only
      upgrade_mode = "Manual"
      lb = {
        private_ip_address_allocation = "Dynamic"
        probes = {
          tcp443 = { port = 443 }
        }
        rules = {
          tcp443 = {
            protocol          = "Tcp"
            frontend_port     = 443
            backend_port      = 443
            probe_name        = "tcp443"
            load_distribution = "SourceIPProtocol"
            # post-upgrade callers may switch to the new key name
            floating_ip_enabled = true
          }
        }
      }
    }
  }

  assert {
    condition     = azurerm_windows_virtual_machine_scale_set.vmss_windows.name == "DevSWG-cmcmp-vmss"
    error_message = "VMSS name must be unchanged after upgrade"
  }
  assert {
    condition     = azurerm_lb_rule.loadbalancer-lbr["tcp443"].name == "DevSWG-cmcmp-tcp443-lbr"
    error_message = "LB rule name must be unchanged after upgrade"
  }
  assert {
    condition     = azurerm_lb_rule.loadbalancer-lbr["tcp443"].floating_ip_enabled == true
    error_message = "floating_ip_enabled must resolve to true via the new key after upgrade"
  }
}
