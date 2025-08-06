# Outputs for ELBE infrastructure

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.elbe.name
}

output "virtual_network_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.elbe.name
}

output "subnet_elbe_id" {
  description = "ID of the ELBE subnet"
  value       = azurerm_subnet.elbe.id
}

output "subnet_admin_id" {
  description = "ID of the admin subnet"
  value       = azurerm_subnet.admin.id
}

output "server_details" {
  description = "Details of all deployed servers"
  value = {
    for key, server in module.elbe_servers : key => {
      name       = server.vm_name
      private_ip = server.private_ip_address
      public_ip  = server.public_ip_address
      fqdn       = server.fqdn
      role       = var.servers[key].role
    }
  }
}

output "domain_controller_ips" {
  description = "IP addresses of domain controllers"
  value = [
    for key, server in var.servers : server.ip_address
    if contains(["primary-dc", "secondary-dc"], server.role)
  ]
}

output "rds_server_ips" {
  description = "IP addresses of RDS servers"
  value = [
    for key, server in var.servers : server.ip_address
    if server.role == "rds-server"
  ]
}

output "admin_server_ip" {
  description = "IP address of admin server"
  value = [
    for key, server in var.servers : server.ip_address
    if server.role == "admin-server"
  ][0]
}

output "ansible_inventory" {
  description = "Ansible inventory in INI format"
  value = templatefile("${path.module}/templates/inventory.tpl", {
    servers = {
      for key, server in module.elbe_servers : key => {
        name       = server.vm_name
        private_ip = server.private_ip_address
        public_ip  = server.public_ip_address
        role       = var.servers[key].role
      }
    }
    domain_name = var.domain_name
  })
}