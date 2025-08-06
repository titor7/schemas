# Main Terraform configuration for ELBE infrastructure

terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "elbe" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Virtual Network
resource "azurerm_virtual_network" "elbe" {
  name                = var.vnet_name
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.elbe.location
  resource_group_name = azurerm_resource_group.elbe.name
  tags                = var.tags
}

# Subnets
resource "azurerm_subnet" "elbe" {
  name                 = "subnet-elbe-vlan213"
  resource_group_name  = azurerm_resource_group.elbe.name
  virtual_network_name = azurerm_virtual_network.elbe.name
  address_prefixes     = [var.subnet_elbe_address_prefix]
}

resource "azurerm_subnet" "admin" {
  name                 = "subnet-admin-vlan213"
  resource_group_name  = azurerm_resource_group.elbe.name
  virtual_network_name = azurerm_virtual_network.elbe.name
  address_prefixes     = [var.subnet_admin_address_prefix]
}

# Network Security Group with rules for AD services
resource "azurerm_network_security_group" "elbe" {
  name                = "nsg-elbe"
  location            = azurerm_resource_group.elbe.location
  resource_group_name = azurerm_resource_group.elbe.name
  tags                = var.tags

  # Kerberos
  security_rule {
    name                       = "Kerberos"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "88"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  # NTP
  security_rule {
    name                       = "NTP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "123"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  # RPC Endpoint Mapper
  security_rule {
    name                       = "RPC"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "135"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  # SMB
  security_rule {
    name                       = "SMB"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "445"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  # Kerberos Change Password
  security_rule {
    name                       = "Kerberos-Change-Password"
    priority                   = 140
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "464"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  # LDAPS
  security_rule {
    name                       = "LDAPS"
    priority                   = 150
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "636"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  # Global Catalog SSL
  security_rule {
    name                       = "Global-Catalog-SSL"
    priority                   = 160
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3269"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  # WinRM
  security_rule {
    name                       = "WinRM"
    priority                   = 170
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5985"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  # ADWS
  security_rule {
    name                       = "ADWS"
    priority                   = 180
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9389"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  # RPC Dynamic Range
  security_rule {
    name                       = "RPC-Dynamic"
    priority                   = 190
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "49152-65535"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  # RDP for management
  security_rule {
    name                       = "RDP"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }
}

# Associate NSG with subnets
resource "azurerm_subnet_network_security_group_association" "elbe" {
  subnet_id                 = azurerm_subnet.elbe.id
  network_security_group_id = azurerm_network_security_group.elbe.id
}

resource "azurerm_subnet_network_security_group_association" "admin" {
  subnet_id                 = azurerm_subnet.admin.id
  network_security_group_id = azurerm_network_security_group.elbe.id
}

# Deploy servers using module
module "elbe_servers" {
  source = "./modules/windows-server"

  for_each = var.servers

  resource_group_name = azurerm_resource_group.elbe.name
  location            = azurerm_resource_group.elbe.location
  tags                = var.tags

  server_name     = each.value.name
  vm_size         = each.value.vm_size
  admin_username  = var.admin_username
  admin_password  = var.admin_password
  os_disk_size_gb = each.value.os_disk_size_gb

  subnet_id   = each.value.subnet == "elbe" ? azurerm_subnet.elbe.id : azurerm_subnet.admin.id
  private_ip  = each.value.ip_address
  server_role = each.value.role

  depends_on = [
    azurerm_subnet_network_security_group_association.elbe,
    azurerm_subnet_network_security_group_association.admin
  ]
}