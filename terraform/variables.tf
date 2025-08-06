# Variables for ELBE infrastructure deployment

variable "resource_group_name" {
  description = "Name of the Azure Resource Group"
  type        = string
  default     = "rg-elbe-infrastructure"
}

variable "location" {
  description = "Azure region for deployment"
  type        = string
  default     = "West Europe"
}

variable "vnet_name" {
  description = "Virtual Network name"
  type        = string
  default     = "vnet-elbe"
}

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["179.105.0.0/16"]
}

variable "subnet_elbe_address_prefix" {
  description = "Address prefix for ELBE subnet (VLAN 213)"
  type        = string
  default     = "179.105.12.96/27" # Covers 179.105.12.98-99
}

variable "subnet_admin_address_prefix" {
  description = "Address prefix for admin subnet"
  type        = string
  default     = "179.105.13.0/24" # Covers 179.105.13.9 and 179.105.13.81
}

variable "domain_name" {
  description = "Active Directory domain name"
  type        = string
  default     = "elbe.its.dnsi"
}

variable "admin_username" {
  description = "Administrator username for VMs"
  type        = string
  default     = "azureuser"
}

variable "admin_password" {
  description = "Administrator password for VMs"
  type        = string
  sensitive   = true
}

variable "vm_size_dc" {
  description = "VM size for domain controllers"
  type        = string
  default     = "Standard_DS2_v2"
}

variable "vm_size_standard" {
  description = "VM size for standard servers"
  type        = string
  default     = "Standard_DS1_v2"
}

variable "vm_size_rds" {
  description = "VM size for RDS servers"
  type        = string
  default     = "Standard_DS3_v2"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Environment = "Production"
    Project     = "ELBE-Infrastructure"
    Owner       = "IT-Administration"
  }
}

# Server definitions
variable "servers" {
  description = "Configuration for ELBE servers"
  type = map(object({
    name            = string
    ip_address      = string
    subnet          = string
    vm_size         = string
    role            = string
    os_disk_size_gb = number
  }))
  default = {
    "elbe-n998" = {
      name            = "ELBE-N998"
      ip_address      = "179.105.12.98"
      subnet          = "elbe"
      vm_size         = "Standard_DS2_v2"
      role            = "primary-dc"
      os_disk_size_gb = 128
    }
    "elbe-n999" = {
      name            = "ELBE-N999"
      ip_address      = "179.105.12.99"
      subnet          = "elbe"
      vm_size         = "Standard_DS2_v2"
      role            = "secondary-dc"
      os_disk_size_gb = 128
    }
    "elbe-v909" = {
      name            = "ELBE-V909"
      ip_address      = "179.105.13.9"
      subnet          = "admin"
      vm_size         = "Standard_DS1_v2"
      role            = "admin-server"
      os_disk_size_gb = 128
    }
    "elbe-v981" = {
      name            = "ELBE-V981"
      ip_address      = "179.105.13.81"
      subnet          = "admin"
      vm_size         = "Standard_DS3_v2"
      role            = "rds-server"
      os_disk_size_gb = 256
    }
    "elbe-v982" = {
      name            = "ELBE-V982"
      ip_address      = "179.105.13.82" # Fixed IP to avoid conflict
      subnet          = "admin"
      vm_size         = "Standard_DS3_v2"
      role            = "rds-server"
      os_disk_size_gb = 256
    }
  }
}