variable "name" {}

variable "environment" {
  default = "dev"
}

variable "location" {}

variable "vnet_resource_group" {}
variable "vnet_name" {}
variable "vnet_subnet" {}

variable "acr_sku" {
  default = "Standard"
}

variable "dns_prefix" {}

variable "kubernetes_version" {
  default = "1.11.5"
}

variable "count" {
  default = "1"
}

variable "vm_size" {}

variable "max_pods" {
  default = "30"
}

variable "os_type" {
  default = "Linux"
}

variable "os_disk_size_gb" {
  default = "30"
}

variable "admin_username" {
  default = "ubuntu"
}

variable "ssh_key_path" {
  default = "~/.ssh/id_rsa.pub"
}

variable "cert_issuer_email" {}
