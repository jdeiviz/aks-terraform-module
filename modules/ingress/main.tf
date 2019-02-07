resource "azurerm_public_ip" "public_ingress" {
  name                = "${var.name}-aks-${var.environment}-ingress-lb-public-ip"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group}"
  allocation_method   = "Static"

  tags {
    component   = "aks"
    environment = "${var.environment}"
  }
}

resource "helm_release" "public_ingress" {
  name  = "ingress-controller-public"
  chart = "stable/nginx-ingress"
  namespace = "kube-system"
  
  values = ["${file("${path.module}/public-ingress.yaml")}"]
  set = [
    {
      name  = "controller.service.loadBalancerIP"
      value = "${azurerm_public_ip.public_ingress.ip_address}"
    }
  ]
}

resource "helm_release" "private_ingress" {
  name  = "ingress-controller-private"
  chart = "stable/nginx-ingress"
  namespace = "kube-system"
  
  values = ["${file("${path.module}/private-ingress.yaml")}"]  
}

data "kubernetes_service" "private_ingress_lb_ip" {
  metadata {
    name = "${helm_release.private_ingress.name}-nginx-ingress-controller"
    namespace = "kube-system"
  }
}
