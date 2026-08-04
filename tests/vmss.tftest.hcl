# tests/vmss.tftest.hcl
# Functional tests for azurerm_windows_virtual_machine_scale_set and the
# companion azurerm_virtual_machine_scale_set_extension (option-10-customScriptExtension.tf).
# mock_provider intercepts all API calls -- no Azure credentials needed.

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

run "naming_convention" {
  command = plan

  variables {
    vmss = {
      resource_group_name    = "rg-test"
      subnet_name            = "snet-test"
      sku                    = "Standard_D2s_v5"
      instances              = 2
      postfix                = "web"
      userDefinedString      = "myapp"
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
    condition     = azurerm_windows_virtual_machine_scale_set.vmss_windows.name == "DevSWG-myweb-vmss"
    error_message = "Name must follow {env4}{serverType3}-{userDefinedString5}{postfix3} convention"
  }
}

run "default_values" {
  command = plan

  variables {
    vmss = {
      resource_group_name    = "rg-test"
      subnet_name            = "snet-test"
      sku                    = "Standard_D2s_v5"
      instances              = 2
      postfix                = "web"
      userDefinedString      = "myapp"
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
    condition     = azurerm_windows_virtual_machine_scale_set.vmss_windows.admin_username == "azureadmin"
    error_message = "admin_username must default to azureadmin"
  }
  assert {
    condition     = azurerm_windows_virtual_machine_scale_set.vmss_windows.computer_name_prefix == "vmsswin-"
    error_message = "computer_name_prefix must default to vmsswin-"
  }
  assert {
    condition     = azurerm_windows_virtual_machine_scale_set.vmss_windows.upgrade_mode == "Manual"
    error_message = "upgrade_mode must default to Manual"
  }
  assert {
    condition     = azurerm_windows_virtual_machine_scale_set.vmss_windows.priority == "Regular"
    error_message = "priority must default to Regular"
  }
  assert {
    condition     = azurerm_windows_virtual_machine_scale_set.vmss_windows.tags["environment"] == "test"
    error_message = "tags must be wired through to the resource"
  }
  assert {
    condition     = azurerm_windows_virtual_machine_scale_set.vmss_windows.network_interface[0].name == "DevSWG-myweb-nic1"
    error_message = "NIC name must default to <vmss-name>-nic1"
  }
}

run "custom_name_and_nic_overrides" {
  command = plan

  variables {
    vmss = {
      custom_name            = "existing-prod-vmss"
      nic_name               = "existing-prod-nic"
      ip_configuration_name  = "existing-prod-ipconfig"
      resource_group_name    = "rg-test"
      subnet_name            = "snet-test"
      sku                    = "Standard_D2s_v5"
      instances              = 2
      postfix                = "web"
      userDefinedString      = "myapp"
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
    condition     = azurerm_windows_virtual_machine_scale_set.vmss_windows.name == "existing-prod-vmss-vmss"
    error_message = "custom_name override must be honored (still suffixed with -vmss)"
  }
  assert {
    condition     = azurerm_windows_virtual_machine_scale_set.vmss_windows.network_interface[0].name == "existing-prod-nic"
    error_message = "nic_name override must be applied"
  }
  assert {
    condition     = azurerm_windows_virtual_machine_scale_set.vmss_windows.network_interface[0].ip_configuration[0].name == "existing-prod-ipconfig"
    error_message = "ip_configuration_name override must be applied"
  }
}

run "no_custom_data_no_extension" {
  command = plan

  variables {
    vmss = {
      resource_group_name    = "rg-test"
      subnet_name            = "snet-test"
      sku                    = "Standard_D2s_v5"
      instances              = 1
      postfix                = "ext"
      userDefinedString      = "ext"
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
    condition     = length(azurerm_virtual_machine_scale_set_extension.CustomScriptExtension) == 0
    error_message = "extension must not be created when custom_data is not set"
  }
}

run "with_custom_data_creates_extension" {
  command = plan

  variables {
    custom_data = "ZWNobyBoZWxsbw=="
    vmss = {
      resource_group_name    = "rg-test"
      subnet_name            = "snet-test"
      sku                    = "Standard_D2s_v5"
      instances              = 1
      postfix                = "ext"
      userDefinedString      = "ext"
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
    condition     = length(azurerm_virtual_machine_scale_set_extension.CustomScriptExtension) == 1
    error_message = "extension must be created when custom_data is set"
  }
}

run "scale_in_and_identity_and_boot_diagnostics" {
  command = plan

  variables {
    vmss = {
      resource_group_name    = "rg-test"
      subnet_name            = "snet-test"
      sku                    = "Standard_D2s_v5"
      instances              = 2
      postfix                = "adv"
      userDefinedString      = "adv"
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
      scale_in = {
        rule                   = "OldestVM"
        force_deletion_enabled = true
      }
      identity = {
        type = "SystemAssigned"
      }
      boot_diagnostics = {
        storage_account_uri = null
      }
    }
  }

  assert {
    condition     = azurerm_windows_virtual_machine_scale_set.vmss_windows.scale_in[0].rule == "OldestVM"
    error_message = "scale_in.rule must be applied"
  }
  assert {
    condition     = length(azurerm_windows_virtual_machine_scale_set.vmss_windows.identity) == 1
    error_message = "identity block must be created when supplied"
  }
  assert {
    condition     = length(azurerm_windows_virtual_machine_scale_set.vmss_windows.boot_diagnostics) == 1
    error_message = "boot_diagnostics block must be created when supplied"
  }
}

run "spot_priority" {
  command = plan

  variables {
    vmss = {
      resource_group_name    = "rg-test"
      subnet_name            = "snet-test"
      sku                    = "Standard_D2s_v5"
      instances              = 1
      postfix                = "spt"
      userDefinedString      = "spt"
      overprovision          = false
      single_placement_group = true
      priority               = "Spot"
      eviction_policy        = "Deallocate"
      max_bid_price          = -1
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
    condition     = azurerm_windows_virtual_machine_scale_set.vmss_windows.priority == "Spot"
    error_message = "priority must be Spot when requested"
  }
  assert {
    condition     = azurerm_windows_virtual_machine_scale_set.vmss_windows.eviction_policy == "Deallocate"
    error_message = "eviction_policy must be applied when priority = Spot"
  }
}
