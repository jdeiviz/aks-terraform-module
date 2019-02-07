
resource "azurerm_container_registry" "acr" {
  name                = "${var.name}acr${var.environment}"
  resource_group_name = "${var.resource_group}"
  location            = "${var.location}"
  admin_enabled       = true
  sku                 = "${var.sku}"  

  tags {
    component   = "aks"
  }
}
