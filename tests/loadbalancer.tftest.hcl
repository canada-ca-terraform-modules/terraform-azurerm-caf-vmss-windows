# tests/loadbalancer.tftest.hcl
# Functional tests for azurerm_lb, azurerm_lb_probe, azurerm_lb_backend_address_pool
# and azurerm_lb_rule (loadbalancer.tf). mock_provider intercepts all API calls.

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

run "no_lb_by_default" {
  command = plan

  variables {
    vmss = {
      resource_group_name    = "rg-test"
      subnet_name            = "snet-test"
      sku                    = "Standard_D2s_v5"
      instances              = 1
      postfix                = "lb"
      userDefinedString      = "lb"
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
    }
  }

  assert {
    condition     = length(azurerm_lb.loadbalancer) == 0
    error_message = "no load balancer must be created when lb is not supplied"
  }
  assert {
    condition     = length(azurerm_lb_backend_address_pool.loadbalancer-lbbp) == 0
    error_message = "no backend pool must be created when lb is not supplied"
  }
}

run "lb_created_with_defaults" {
  command = plan

  variables {
    vmss = {
      resource_group_name    = "rg-test"
      subnet_name            = "snet-test"
      sku                    = "Standard_D2s_v5"
      instances              = 1
      postfix                = "lb"
      userDefinedString      = "lb"
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
  }

  assert {
    condition     = length(azurerm_lb.loadbalancer) == 1
    error_message = "load balancer must be created when lb is supplied"
  }
  assert {
    condition     = azurerm_lb.loadbalancer[0].name == "DevSWG-lblb-lb"
    error_message = "lb name must default to <vmss-name>-lb"
  }
  assert {
    condition     = azurerm_lb.loadbalancer[0].sku == "Standard"
    error_message = "lb sku must default to Standard"
  }
  assert {
    condition     = azurerm_lb_backend_address_pool.loadbalancer-lbbp[0].name == "DevSWG-lblb-HA-lbbp"
    error_message = "backend pool name must default to <vmss-name>-HA-lbbp"
  }
  assert {
    condition     = azurerm_lb_probe.loadbalancer-lbhp["tcp443"].name == "DevSWG-lblb-tcp443-lbhp"
    error_message = "probe name must default to <vmss-name>-<key>-lbhp"
  }
  assert {
    condition     = azurerm_lb_probe.loadbalancer-lbhp["tcp443"].protocol == "Tcp"
    error_message = "probe protocol must default to Tcp"
  }
  assert {
    condition     = azurerm_lb_probe.loadbalancer-lbhp["tcp443"].number_of_probes == 2
    error_message = "number_of_probes must default to 2"
  }
  assert {
    condition     = azurerm_lb_rule.loadbalancer-lbr["tcp443"].name == "DevSWG-lblb-tcp443-lbr"
    error_message = "rule name must default to <vmss-name>-<key>-lbr"
  }
  assert {
    condition     = azurerm_lb_rule.loadbalancer-lbr["tcp443"].floating_ip_enabled == true
    error_message = "floating_ip_enabled must be applied when supplied via new key"
  }
}

run "lb_legacy_enable_floating_ip_key_still_works" {
  command = plan

  variables {
    vmss = {
      resource_group_name    = "rg-test"
      subnet_name            = "snet-test"
      sku                    = "Standard_D2s_v5"
      instances              = 1
      postfix                = "lb"
      userDefinedString      = "lb"
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
          tcp80 = { port = 80 }
        }
        rules = {
          tcp80 = {
            protocol           = "Tcp"
            frontend_port      = 80
            backend_port       = 80
            probe_name         = "tcp80"
            load_distribution  = "SourceIPProtocol"
            enable_floating_ip = true
          }
        }
      }
    }
  }

  assert {
    condition     = azurerm_lb_rule.loadbalancer-lbr["tcp80"].floating_ip_enabled == true
    error_message = "legacy enable_floating_ip key must still map to floating_ip_enabled"
  }
}

run "name_overrides_and_new_optional_args" {
  command = plan

  variables {
    vmss = {
      resource_group_name    = "rg-test"
      subnet_name            = "snet-test"
      sku                    = "Standard_D2s_v5"
      instances              = 1
      postfix                = "lb"
      userDefinedString      = "lb"
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
        name                          = "existing-prod-lb"
        backend_pool_name             = "existing-prod-lbbp"
        private_ip_address_allocation = "Dynamic"
        sku_tier                      = "Regional"
        probes = {
          tcp443 = {
            name            = "existing-prod-probe"
            port            = 443
            probe_threshold = 2
          }
        }
        rules = {
          tcp443 = {
            name                  = "existing-prod-rule"
            protocol              = "Tcp"
            frontend_port         = 443
            backend_port          = 443
            probe_name            = "tcp443"
            load_distribution     = "SourceIPProtocol"
            floating_ip_enabled   = true
            disable_outbound_snat = true
            tcp_reset_enabled     = true
          }
        }
      }
    }
  }

  assert {
    condition     = azurerm_lb.loadbalancer[0].name == "existing-prod-lb"
    error_message = "lb name override must be applied"
  }
  assert {
    condition     = azurerm_lb.loadbalancer[0].sku_tier == "Regional"
    error_message = "sku_tier must be applied when supplied"
  }
  assert {
    condition     = azurerm_lb_backend_address_pool.loadbalancer-lbbp[0].name == "existing-prod-lbbp"
    error_message = "backend_pool_name override must be applied"
  }
  assert {
    condition     = azurerm_lb_probe.loadbalancer-lbhp["tcp443"].name == "existing-prod-probe"
    error_message = "probe name override must be applied"
  }
  assert {
    condition     = azurerm_lb_probe.loadbalancer-lbhp["tcp443"].probe_threshold == 2
    error_message = "probe_threshold must be applied when supplied"
  }
  assert {
    condition     = azurerm_lb_rule.loadbalancer-lbr["tcp443"].name == "existing-prod-rule"
    error_message = "rule name override must be applied"
  }
  assert {
    condition     = azurerm_lb_rule.loadbalancer-lbr["tcp443"].disable_outbound_snat == true
    error_message = "disable_outbound_snat must be applied when supplied"
  }
  assert {
    condition     = azurerm_lb_rule.loadbalancer-lbr["tcp443"].tcp_reset_enabled == true
    error_message = "tcp_reset_enabled must be applied when supplied"
  }
}
