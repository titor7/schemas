# Windows Server module outputs

output "vm_name" {
  description = "Name of the virtual machine"
  value       = azurerm_windows_virtual_machine.server.name
}

output "vm_id" {
  description = "ID of the virtual machine"
  value       = azurerm_windows_virtual_machine.server.id
}

output "private_ip_address" {
  description = "Private IP address of the VM"
  value       = azurerm_network_interface.server.ip_configuration[0].private_ip_address
}

output "public_ip_address" {
  description = "Public IP address of the VM"
  value       = azurerm_public_ip.server.ip_address
}

output "fqdn" {
  description = "Fully qualified domain name"
  value       = azurerm_public_ip.server.fqdn
}

output "network_interface_id" {
  description = "ID of the network interface"
  value       = azurerm_network_interface.server.id
}