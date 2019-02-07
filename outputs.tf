output "resource_group" {
  value = "${var.name}-aks-${var.environment}-rg"
}

output "name" {
  value = "${var.name}-aks-${var.environment}"
}

output "fqdn" {
  value = "${azurerm_kubernetes_cluster.aks.fqdn}"
}

output "kube_admin_config" {
  value = "${azurerm_kubernetes_cluster.aks.kube_admin_config}"
}

output "kube_admin_config_raw" {
  value = "${azurerm_kubernetes_cluster.aks.kube_admin_config_raw}"
}

output "kube_config" {
  value = "${azurerm_kubernetes_cluster.aks.fqdn}"
}

output "kube_config_raw" {
  value = "${azurerm_kubernetes_cluster.aks.kube_config_raw}"
}

output "public_ingress_lb_ip" {
  value = "${module.ingress.public_ingress_lb_ip}"
}

output "private_ingress_lb_ip" {
  value = "${module.ingress.private_ingress_lb_ip}"
}
