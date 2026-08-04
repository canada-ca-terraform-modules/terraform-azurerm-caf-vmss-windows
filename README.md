# terraform-azurerm-caf-vmss-windows

Terraform CAF module for deploying a Windows Virtual Machine Scale Set (`azurerm_windows_virtual_machine_scale_set`), with an optional
Standard Load Balancer (`azurerm_lb`, `azurerm_lb_probe`, `azurerm_lb_backend_address_pool`, `azurerm_lb_rule`) and an optional
Custom Script Extension (`azurerm_virtual_machine_scale_set_extension`).

## Usage

### ESLZ module block (`ESLZ/vmss-windows.tf`)

```hcl
module "vmss_windows" {
  source   = "github.com/canada-ca-terraform-modules/terraform-azurerm-caf-vmss-windows?ref=v1.3.0"
  for_each = var.vmss_windows

  tags            = var.tags
  env             = var.env
  location        = var.location
  resource_groups = var.resource_groups
  subnets         = var.subnets
  admin_password  = var.admin_password
  custom_data     = try(each.value.custom_data, var.custom_data)
  vmss            = each.value
}
```

### ESLZ tfvars pattern (`ESLZ/vmss-windows.tfvars`)

```hcl
vmss_windows = {
  web01 = {
    resource_group_name = "rg-example"
    subnet_name         = "snet-example"
    sku                 = "Standard_D2s_v5"
    instances           = 2
    postfix             = "web"
    userDefinedString   = "myapp"

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
```

See `ESLZ/vmss-windows.tfvars` for the full set of commented, optional arguments (load balancer,
identity, boot diagnostics, upgrade policies, Spot pricing, name overrides, etc.).

## Naming convention

The VMSS name is generated as `{env:4}SWG-{userDefinedString:5-len(postfix)}{postfix:3}`, e.g.
`env = "Dev"`, `postfix = "web"`, `userDefinedString = "myapp"` produces `DevSWG-myweb`. Use
`vmss.custom_name` to override the generated name entirely.

## New arguments (azurerm >= 5.0)

### `vmss` — new top-level keys

| Key | Type | Description |
|---|---|---|
| `upgrade_mode` | string | `Automatic`, `Manual` (default) or `Rolling` |
| `health_probe_id` | string | Required (and only valid) when `upgrade_mode` is `Automatic` or `Rolling` |
| `zones` | list(string) | Availability zones (optional) |
| `priority` | string | `Regular` (default) or `Spot` |
| `eviction_policy` | string | Only valid when `priority = Spot` |
| `max_bid_price` | number | Only valid when `priority = Spot` |
| `encryption_at_host_enabled` | bool | Optional |
| `license_type` | string | Optional (Azure Hybrid Benefit) |
| `identity` | object | Optional `identity` block |
| `boot_diagnostics` | object | Optional `boot_diagnostics` block |
| `automatic_os_upgrade_policy` | object | Only valid when `upgrade_mode` is `Automatic` or `Rolling` |
| `rolling_upgrade_policy` | object | Only valid when `upgrade_mode` is `Automatic` or `Rolling` |
| `nic_name` | string | Optional: override the auto-generated NIC name |
| `ip_configuration_name` | string | Optional: override the auto-generated IP configuration name |

### `vmss.lb` — new/changed keys

| Key | Type | Description |
|---|---|---|
| `name` | string | Optional: override the auto-generated load balancer name |
| `backend_pool_name` | string | Optional: override the auto-generated backend pool name |
| `sku_tier` | string | Optional: `Global` or `Regional` |
| `probes.*.name` | string | Optional: override the auto-generated probe name |
| `probes.*.probe_threshold` | number | Optional |
| `rules.*.name` | string | Optional: override the auto-generated rule name |
| `rules.*.floating_ip_enabled` | bool | **Renamed** from `enable_floating_ip` (azurerm >= 5.0). `enable_floating_ip` is still accepted for backward compatibility. |
| `rules.*.disable_outbound_snat` | bool | Optional |
| `rules.*.tcp_reset_enabled` | bool | Optional |

## Testing

```bash
terraform fmt -recursive && terraform init -backend=false && terraform validate && terraform test
```

## CI

GitHub Actions workflow at [.github/workflows/terraform-ci.yml](.github/workflows/terraform-ci.yml) runs fmt, init, validate, test, and tflint on every PR.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | ~> 5.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_lb.loadbalancer](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb) | resource |
| [azurerm_lb_backend_address_pool.loadbalancer-lbbp](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb_backend_address_pool) | resource |
| [azurerm_lb_probe.loadbalancer-lbhp](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb_probe) | resource |
| [azurerm_lb_rule.loadbalancer-lbr](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb_rule) | resource |
| [azurerm_virtual_machine_scale_set_extension.CustomScriptExtension](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_scale_set_extension) | resource |
| [azurerm_windows_virtual_machine_scale_set.vmss_windows](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/windows_virtual_machine_scale_set) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admin_password"></a> [admin\_password](#input\_admin\_password) | The password for the local administrator account on the virtual machine | `string` | n/a | yes |
| <a name="input_custom_data"></a> [custom\_data](#input\_custom\_data) | Specifies custom data to supply to the VM Scale set | `string` | `null` | no |
| <a name="input_env"></a> [env](#input\_env) | 4 characters defining the environment name prefix for the scale set | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | Azure location in which the scale set is deployed | `string` | n/a | yes |
| <a name="input_resource_groups"></a> [resource\_groups](#input\_resource\_groups) | List of resource groups objets | `any` | n/a | yes |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | List of subnets objects | `any` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags that will be associated with the ressource | `map(string)` | n/a | yes |
| <a name="input_vmss"></a> [vmss](#input\_vmss) | Details about vmss config | `any` | `{}` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
