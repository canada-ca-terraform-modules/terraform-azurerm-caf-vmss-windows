resource "azurerm_windows_virtual_machine_scale_set" "vmss_windows" {
  name                            = "${local.vmss_name}-vmss"
  location                        = var.location
  resource_group_name             = var.resource_groups[var.vmss.resource_group_name].name
  sku                             = var.vmss.sku
  instances                       = var.vmss.instances
  admin_username                  = try(var.vmss.admin_username, "azureadmin")
  admin_password                  = var.admin_password
  computer_name_prefix            = try(var.vmss.computer_name_prefix, null) # Optional. eg: "vmsswin-"

  overprovision          = var.vmss.overprovision
  single_placement_group = var.vmss.single_placement_group

  source_image_reference {
    publisher = var.vmss.source_image_reference.publisher
    offer     = var.vmss.source_image_reference.offer
    sku       = var.vmss.source_image_reference.sku
    version   = var.vmss.source_image_reference.version
  }

  # automatic_os_upgrade_policy {
  #         disable_automatic_rollback  = null
  #         enable_automatic_os_upgrade =  null
  #       }

  os_disk {
    storage_account_type = var.vmss.os_disk.storage_account_type
    caching              = var.vmss.os_disk.caching
  }

  network_interface {
    name    = "${local.vmss_name}-nic1"
    primary = true

    ip_configuration {
      name      = "ipconfig1"
      primary   = true
      subnet_id = var.subnets[var.vmss.subnet_name].id
    }
  }

  lifecycle {
    ignore_changes = [tags, instances] # ignore changes made to tags by App Services
  }
}