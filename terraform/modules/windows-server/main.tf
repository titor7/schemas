# Windows Server module main configuration

# Public IP for management
resource "azurerm_public_ip" "server" {
  name                = "pip-${var.server_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = lower(var.server_name)
  tags                = var.tags
}

# Network Interface
resource "azurerm_network_interface" "server" {
  name                = "nic-${var.server_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.private_ip
    public_ip_address_id          = azurerm_public_ip.server.id
  }
}

# Virtual Machine
resource "azurerm_windows_virtual_machine" "server" {
  name                = var.server_name
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  tags                = var.tags



  network_interface_ids = [
    azurerm_network_interface.server.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = var.os_disk_size_gb
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  # Enable WinRM for Ansible
  additional_unattend_content {
    setting = "AutoLogon"
    content = "<AutoLogon><Password><Value>${var.admin_password}</Value></Password><Enabled>true</Enabled><LogonCount>1</LogonCount><Username>${var.admin_username}</Username></AutoLogon>"
  }

  additional_unattend_content {
    setting = "FirstLogonCommands"
    content = file("${path.module}/scripts/ConfigureRemotingForAnsible.xml")
  }
}

# VM Extension for initial configuration
resource "azurerm_virtual_machine_extension" "winrm" {
  name                 = "winrm-${var.server_name}"
  virtual_machine_id   = azurerm_windows_virtual_machine.server.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"
  tags                 = var.tags

  settings = jsonencode({
    "fileUris" = [
      "https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1"
    ]
    "commandToExecute" = "powershell -ExecutionPolicy Unrestricted -File ConfigureRemotingForAnsible.ps1 -EnableCredSSP"
  })
}