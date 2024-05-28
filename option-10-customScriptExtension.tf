variable "custom_data"{
    description = "Specifies custom data to supply to the VM Scale set"
    type = string
    default = null
}

resource "azurerm_virtual_machine_scale_set_extension" "CustomScriptExtension" {
  count = var.custom_data != null ? 1 : 0
  name = "CustomScriptExtension"
  virtual_machine_scale_set_id = azurerm_windows_virtual_machine_scale_set.vmss_windows.id
  publisher = "Microsoft.Compute"
  type = "CustomScriptExtension"
  type_handler_version = "1.10.16"
  
  settings = jsonencode({
    "commandToExecute" = "powershell -command Set-ExecutionPolicy RemoteSigned -force; powershell -command copy-item \"c:\\AzureData\\CustomData.bin\" \"c:\\AzureData\\CustomData.ps1\";\"c:\\AzureData\\CustomData.ps1\""
  })
}