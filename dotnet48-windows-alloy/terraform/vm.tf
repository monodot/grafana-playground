# Windows VMs
resource "azurerm_windows_virtual_machine" "main" {
  count               = var.vm_count
  name                = "${var.prefix}-vm-${count.index}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  network_interface_ids = [
    azurerm_network_interface.main[count.index].id,
  ]
  vm_agent_platform_updates_enabled = false

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }
}

# Add bootstrap script and alloy config to the machine
resource "azurerm_virtual_machine_extension" "setup" {
  count                = var.vm_count
  name                 = "setup-script"
  virtual_machine_id   = azurerm_windows_virtual_machine.main[count.index].id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = jsonencode({
    commandToExecute = "powershell -ExecutionPolicy Unrestricted -File setup.ps1"
  })

  protected_settings = jsonencode({
    fileUris = [
      "${azurerm_storage_blob.setup_script.url}${data.azurerm_storage_account_blob_container_sas.scripts.sas}",
      "${azurerm_storage_blob.alloy_config.url}${data.azurerm_storage_account_blob_container_sas.scripts.sas}",
      "${azurerm_storage_blob.app_default_aspx.url}${data.azurerm_storage_account_blob_container_sas.scripts.sas}",
      "${azurerm_storage_blob.app_web_config.url}${data.azurerm_storage_account_blob_container_sas.scripts.sas}"
    ]
  })
}
