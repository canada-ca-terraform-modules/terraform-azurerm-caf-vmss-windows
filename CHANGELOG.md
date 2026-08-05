# Changelog

All notable changes to this module are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [1.3.0] - 2026-08-04

### Added

- `providers.tf` pinning `azurerm ~> 5.0` (previously absent — module had no explicit provider constraint).
- `tests/` directory with `vmss.tftest.hcl`, `loadbalancer.tftest.hcl`, and `upgrade_compat.tftest.hcl` (`terraform test`, mock provider, no credentials required).
- `.tflint.hcl` and CI enforcement via `.github/workflows/terraform-ci.yml`.
- `.github/workflows/release.yml` — creates a GitHub release on merge to `main`, tagged from the version pinned in `ESLZ/vmss-windows.tf`.
- `ESLZ/vmss-windows.tf` and `ESLZ/vmss-windows.tfvars` — the module block and tfvars example callers copy into their L2 blueprint (previously absent).
- `azurerm_windows_virtual_machine_scale_set`: new optional arguments `upgrade_mode`, `health_probe_id`, `zones`, `priority`, `eviction_policy`, `max_bid_price`, `encryption_at_host_enabled`, `license_type`, `provision_vm_agent`, `automatic_updates_enabled`, and optional `identity`, `boot_diagnostics`, `automatic_os_upgrade_policy`, `rolling_upgrade_policy` blocks. All gated with `try(..., null)` / dynamic blocks — no impact on existing configuration.
- Optional name overrides (Pattern 12) for the VMSS network interface (`nic_name`), IP configuration (`ip_configuration_name`), load balancer (`lb.name`), backend address pool (`lb.backend_pool_name`), probes (`lb.probes.*.name`), and rules (`lb.rules.*.name`) — lets callers whose real resource names diverge from the generated formula pin them without destroy/recreate.
- `azurerm_lb`: optional `sku_tier`.
- `azurerm_lb_probe`: optional `probe_threshold`.
- `azurerm_lb_backend_address_pool`: optional `virtual_network_id`, `synchronous_mode`.
- `azurerm_lb_rule`: optional `disable_outbound_snat`, `tcp_reset_enabled`.

### Changed

- `azurerm_lb_rule.loadbalancer-lbr`: `enable_floating_ip` renamed to `floating_ip_enabled` to match the azurerm >= 5.0 provider schema. Backward compatible — `try(each.value.floating_ip_enabled, each.value.enable_floating_ip)` continues to accept the legacy `enable_floating_ip` key in existing `lb.rules.*` tfvars.
- `azurerm_windows_virtual_machine_scale_set.vmss_windows`: `tags = var.tags` is now actually wired to the resource. Previously the `tags` variable was declared and referenced in `lifecycle.ignore_changes`, but never applied — tags were silently never set by this module.
- `azurerm_lb.loadbalancer`: `tags = var.tags` added (same bug as above — the resource never received tags).

### Known blockers

- None. No child modules, no provider constraint conflicts.
