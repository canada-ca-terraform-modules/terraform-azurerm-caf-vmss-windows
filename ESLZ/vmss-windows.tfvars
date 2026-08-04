# ESLZ/vmss-windows.tfvars
# Rules: existing entries unchanged; new args go below, commented out with explanation

vmss_windows = {
  # --- EXAMPLE ENTRY ---
  web01 = {
    resource_group    = "rg-example"
    subnet_name       = "snet-example"
    sku               = "Standard_D2s_v5"
    instances         = 2
    postfix           = "web"
    userDefinedString = "myapp"
    # admin_username       = "azureadmin"       # Optional. Default: azureadmin
    # computer_name_prefix = "vmsswin-"          # Optional. Default: vmsswin-
    # custom_name          = ""                  # Optional: Override the auto-generated VMSS name
    # nic_name             = ""                  # Optional: Override the auto-generated NIC name (default: <vmss-name>-nic1)
    # ip_configuration_name = ""                 # Optional: Override the auto-generated IP configuration name (default: ipconfig1)

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

    # --- NEW ARGUMENT EXAMPLES (commented out) ---
    # upgrade_mode    = "Manual"  # Optional. Possible values: Automatic, Manual (default), Rolling
    # health_probe_id = ""        # Optional. Required (and only valid) when upgrade_mode = Automatic or Rolling
    # zones                      = ["1", "2", "3"]  # Optional
    # priority                   = "Regular"         # Optional. Possible values: Regular (default), Spot
    # eviction_policy            = "Deallocate"       # Optional. Only valid when priority = Spot
    # max_bid_price              = -1                 # Optional. Only valid when priority = Spot
    # encryption_at_host_enabled = false               # Optional
    # license_type               = "Windows_Server"    # Optional
    # provision_vm_agent         = true                # Optional. Default: true
    # automatic_updates_enabled  = true                # Optional. Default: true
    #
    # identity = {
    #   type         = "SystemAssigned"
    #   identity_ids = []
    # }
    #
    # boot_diagnostics = {
    #   storage_account_uri = null # null uses a Managed Storage Account
    # }
    #
    # automatic_os_upgrade_policy = {
    #   automatic_rollback_enabled   = true
    #   automatic_os_upgrade_enabled = true
    # }
    #
    # rolling_upgrade_policy = {
    #   max_batch_instance_percent             = 20
    #   max_unhealthy_instance_percent         = 20
    #   max_unhealthy_upgraded_instance_percent = 5
    #   pause_time_between_batches             = "PT0S"
    # }

    # Optional: attach a load balancer. See loadbalancer.tf for full documentation.
    # lb = {
    #   sku = "Standard"
    #   # sku_tier = "Regional" # Optional (azurerm >= 4.x)
    #   probes = {
    #     tcp443 = {
    #       port                = 443
    #       interval_in_seconds = 5
    #       # probe_threshold   = 1 # Optional (azurerm >= 4.x)
    #     }
    #   }
    #   rules = {
    #     tcp443 = {
    #       protocol            = "Tcp"
    #       frontend_port       = 443
    #       backend_port        = 443
    #       probe_name          = "tcp443"
    #       load_distribution   = "SourceIPProtocol"
    #       floating_ip_enabled = true # Renamed from enable_floating_ip in azurerm >= 5.0
    #     }
    #   }
    # }
  }
}
