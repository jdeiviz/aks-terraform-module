data "azurerm_resource_group" "rg_vnet_shared" {
  name                = "${var.vnet_resource_group}"
}

data "azurerm_virtual_network" "vnet_shared" {
  name                = "${var.vnet_name}"
  resource_group_name = "${data.azurerm_resource_group.rg_vnet_shared.name}"
}

data "azurerm_subnet" "aks_subnet_shared" {
  name                  = "${var.vnet_subnet}"
  resource_group_name   = "${data.azurerm_resource_group.rg_vnet_shared.name}"
  virtual_network_name  = "${data.azurerm_virtual_network.vnet_shared.name}"
}
