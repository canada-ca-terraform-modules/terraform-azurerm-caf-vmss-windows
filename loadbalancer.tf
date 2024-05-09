/*
Documentation on the lb object required to define the loadbalancer

lb = {
  private_ip_address_allocation = "Dynamic"      # Optional: Dynamic or Static. Default to Static
  # private_ip_address            = "10.10.10.10" # Optional: Use it to configure a specific private IP instead of a dynamic one
  # subnet_name                   = "MAZ"         # Optional. Use only if you want the subnet for the LB NIC to be different than the VMSS
  sku = "Standard" # Optional. Default to Standard
  probes = {
    tcp443 = {
      port = 443 # Port to probe to detect health of vm
      interval_in_seconds = 5 # Optional. Default to 5
    }
  }
  rules = {
    tcp443 = {
      protocol           = "Tcp"
      frontend_port      = 443
      backend_port       = 443
      probe_name         = "tcp443"
      load_distribution  = "SourceIPProtocol"
      enable_floating_ip = true
    },
    tcp80 = {
      protocol           = "TCP"
      frontend_port      = 80
      backend_port       = 80
      probe_name         = "tcp443"
      load_distribution  = "SourceIPProtocol"
      enable_floating_ip = true
    }
  }
}

*/

resource "azurerm_lb" "loadbalancer" {
  # Conditional creation of the load balancer if a load balancer configuration is provided for the VMSS
  count = try(var.vmss.lb, null) != null ? 1 : 0

  # Name and location settings for the load balancer
  name                = "${local.vmss_name}-lb"
  location            = var.location
  resource_group_name = var.resource_groups[var.vmss.resource_group_name].name
  
  # Frontend IP configuration - defines how the load balancer is exposed on the network
  frontend_ip_configuration {
    name                          = "${local.vmss_name}-lbfe"

    # Allocation method for the frontend IP - defaults to 'Static' if not specified
    private_ip_address_allocation = try(var.vmss.lb.private_ip_address_allocation, "Static")

    # Assigns a static IP if the allocation method is 'Static', otherwise no IP is assigned
    private_ip_address            = try(var.vmss.lb.private_ip_address_allocation, "Static") == "Static" ? var.vmss.lb.private_ip_address : null

    # Subnet ID for the frontend IP - defaults to the subnet specified for the load balancer, otherwise uses the VMSS subnet
    subnet_id                     = try(var.subnets[var.vmss.lb.subnet_name].id, var.subnets[var.vmss.subnet_name].id)
  }

  # SKU for the load balancer, defaults to 'Standard' if not specified
  sku = try(var.vmss.lb.sku, "Standard")
}

resource "azurerm_lb_probe" "loadbalancer-lbhp" {
  for_each = try(var.vmss.lb.probes, {})

  # resource_group_name = var.resource_group.name
  loadbalancer_id     = azurerm_lb.loadbalancer[0].id
  name                = "${local.vmss_name}-${each.key}-lbhp"
  protocol            = try(each.value["protocol"], "Tcp")
  port                = each.value.port
  request_path        = try(each.value["request_path"], null)
  interval_in_seconds = try(each.value["interval_in_seconds"], 5)
  number_of_probes    = try(each.value["number_of_probes"], 2)
}

resource "azurerm_lb_backend_address_pool" "loadbalancer-lbbp" {
  count = try(var.vmss.lb, null) != null ? 1 : 0

  loadbalancer_id = azurerm_lb.loadbalancer[0].id
  name            = "${local.vmss_name}-HA-lbbp"
}

resource "azurerm_lb_rule" "loadbalancer-lbr" {
  for_each = try(var.vmss.lb.rules, {})

  # resource_group_name            = var.resource_group.name
  loadbalancer_id                = azurerm_lb.loadbalancer[0].id
  name                           = "${local.vmss_name}-${each.key}-lbr"
  protocol                       = each.value.protocol
  frontend_port                  = each.value.frontend_port
  backend_port                   = each.value.backend_port
  frontend_ip_configuration_name = "${local.vmss_name}-lbfe"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.loadbalancer-lbbp[0].id]
  probe_id                       = azurerm_lb_probe.loadbalancer-lbhp["${each.value.probe_name}"].id
  load_distribution              = each.value.load_distribution
  enable_floating_ip             = each.value.enable_floating_ip
  idle_timeout_in_minutes        = try(each.value.idle_timeout_in_minutes, 4)
}