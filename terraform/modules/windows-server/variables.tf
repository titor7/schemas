# Windows Server module variables

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}

variable "server_name" {
  description = "Name of the server"
  type        = string
}

variable "vm_size" {
  description = "Size of the virtual machine"
  type        = string
}

variable "admin_username" {
  description = "Administrator username"
  type        = string
}

variable "admin_password" {
  description = "Administrator password"
  type        = string
  sensitive   = true
}

variable "os_disk_size_gb" {
  description = "OS disk size in GB"
  type        = number
  default     = 128
}

variable "subnet_id" {
  description = "ID of the subnet"
  type        = string
}

variable "private_ip" {
  description = "Static private IP address"
  type        = string
}

variable "server_role" {
  description = "Role of the server (primary-dc, secondary-dc, admin-server, rds-server)"
  type        = string
}