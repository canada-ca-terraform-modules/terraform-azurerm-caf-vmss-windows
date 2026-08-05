resource "azurerm_windows_virtual_machine_scale_set" "vmss_windows" {
  name                 = "${local.vmss_name}-vmss"
  location             = var.location
  resource_group_name  = var.resource_groups[var.vmss.resource_group_name].name
  sku                  = var.vmss.sku
  instances            = var.vmss.instances
  admin_username       = try(var.vmss.admin_username, "azureadmin")
  admin_password       = var.admin_password
  computer_name_prefix = try(var.vmss.computer_name_prefix, "vmsswin-") # Optional. eg: "devopsw-"
  custom_data          = var.custom_data
  tags                 = var.tags

  overprovision          = var.vmss.overprovision
  single_placement_group = var.vmss.single_placement_group

  # Optional. Possible values: Automatic, Manual (default), Rolling
  upgrade_mode = try(var.vmss.upgrade_mode, "Manual")

  # Optional. Required (and only valid) when upgrade_mode = Automatic or Rolling
  health_probe_id = try(var.vmss.health_probe_id, null)

  zones                      = try(var.vmss.zones, null)
  priority                   = try(var.vmss.priority, "Regular")
  eviction_policy            = try(var.vmss.eviction_policy, null) # Only valid when priority = Spot
  max_bid_price              = try(var.vmss.max_bid_price, null)   # Only valid when priority = Spot
  encryption_at_host_enabled = try(var.vmss.encryption_at_host_enabled, null)
  license_type               = try(var.vmss.license_type, null)
  provision_vm_agent         = try(var.vmss.provision_vm_agent, true)
  automatic_updates_enabled  = try(var.vmss.automatic_updates_enabled, true)

  source_image_reference {
    publisher = var.vmss.source_image_reference.publisher
    offer     = var.vmss.source_image_reference.offer
    sku       = var.vmss.source_image_reference.sku
    version   = var.vmss.source_image_reference.version
  }

  # Only valid when upgrade_mode = Automatic or Rolling
  dynamic "automatic_os_upgrade_policy" {
    for_each = try(var.vmss.automatic_os_upgrade_policy, null) != null ? [var.vmss.automatic_os_upgrade_policy] : []
    content {
      # automatic_rollback_enabled / automatic_os_upgrade_enabled replace the
      # deprecated disable_automatic_rollback / enable_automatic_os_upgrade
      # argument names (azurerm >= 5.0). Both key names are accepted here.
      automatic_rollback_enabled = try(
        automatic_os_upgrade_policy.value.automatic_rollback_enabled,
        automatic_os_upgrade_policy.value.disable_automatic_rollback,
      )
      automatic_os_upgrade_enabled = try(
        automatic_os_upgrade_policy.value.automatic_os_upgrade_enabled,
        automatic_os_upgrade_policy.value.enable_automatic_os_upgrade,
      )
    }
  }

  # Only valid when upgrade_mode = Automatic or Rolling
  dynamic "rolling_upgrade_policy" {
    for_each = try(var.vmss.rolling_upgrade_policy, null) != null ? [var.vmss.rolling_upgrade_policy] : []
    content {
      max_batch_instance_percent              = rolling_upgrade_policy.value.max_batch_instance_percent
      max_unhealthy_instance_percent          = rolling_upgrade_policy.value.max_unhealthy_instance_percent
      max_unhealthy_upgraded_instance_percent = rolling_upgrade_policy.value.max_unhealthy_upgraded_instance_percent
      pause_time_between_batches              = rolling_upgrade_policy.value.pause_time_between_batches
      cross_zone_upgrades_enabled             = try(rolling_upgrade_policy.value.cross_zone_upgrades_enabled, null)
      prioritize_unhealthy_instances_enabled  = try(rolling_upgrade_policy.value.prioritize_unhealthy_instances_enabled, null)
      maximum_surge_instances_enabled         = try(rolling_upgrade_policy.value.maximum_surge_instances_enabled, null)
    }
  }

  dynamic "identity" {
    for_each = try(var.vmss.identity, null) != null ? [var.vmss.identity] : []
    content {
      type         = identity.value.type
      identity_ids = try(identity.value.identity_ids, null)
    }
  }

  dynamic "boot_diagnostics" {
    for_each = try(var.vmss.boot_diagnostics, null) != null ? [var.vmss.boot_diagnostics] : []
    content {
      storage_account_uri = try(boot_diagnostics.value.storage_account_uri, null)
    }
  }

  dynamic "scale_in" {
    for_each = try(var.vmss.scale_in, null) != null ? [var.vmss.scale_in] : []
    content {
      rule                   = try(scale_in.value.rule, null)
      force_deletion_enabled = try(scale_in.value.force_deletion_enabled, null)
    }
  }

  os_disk {
    storage_account_type = var.vmss.os_disk.storage_account_type
    caching              = var.vmss.os_disk.caching
  }

  network_interface {
    name    = try(var.vmss.nic_name, "${local.vmss_name}-nic1")
    primary = true

    ip_configuration {
      name                                   = try(var.vmss.ip_configuration_name, "ipconfig1")
      primary                                = true
      subnet_id                              = var.subnets[var.vmss.subnet_name].id
      load_balancer_backend_address_pool_ids = try(var.vmss.lb, null) != null ? [azurerm_lb_backend_address_pool.loadbalancer-lbbp[0].id] : null
    }
  }

  lifecycle {
    ignore_changes = [tags, instances] # ignore changes made to tags by App Services
  }
}
