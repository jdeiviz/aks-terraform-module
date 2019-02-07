output "public_ingress_lb_ip" {
  value = "${azurerm_public_ip.public_ingress.ip_address}"
}

output "private_ingress_lb_ip" {
  value = "${data.kubernetes_service.private_ingress_lb_ip.load_balancer_ingress.0.ip}"
}
