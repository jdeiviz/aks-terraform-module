resource "azurerm_log_analytics_workspace" "log_workspace_aks" {
  name                = "${var.name}-aks-${var.environment}-log-workspace"
  resource_group_name = "${var.resource_group}"
  location            = "${var.location}"
  sku                 = "PerGB2018"

  tags {
    component   = "aks"
    environment = "${var.environment}"
  }
}

resource "azurerm_log_analytics_solution" "log_solution_aks" {
  solution_name         = "ContainerInsights"
  resource_group_name   = "${var.resource_group}"
  location              = "${var.location}"
  workspace_resource_id = "${azurerm_log_analytics_workspace.log_workspace_aks.id}"
  workspace_name        = "${azurerm_log_analytics_workspace.log_workspace_aks.name}"

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }
}
