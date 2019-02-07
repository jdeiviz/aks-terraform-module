locals {
  #letsencrypt_environment = "${var.environment == "prod" ? "letsencrypt-prod" : "letsencrypt-staging"}"
  #acme_server = "${var.environment == "prod" ? "https://acme-v02.api.letsencrypt.org/directory" : "https://acme-staging-v02.api.letsencrypt.org/directory"}"
  letsencrypt_environment = "letsencrypt-prod"
  acme_server = "https://acme-v02.api.letsencrypt.org/directory"
}

resource "helm_release" "cert_manager" {
  name  = "cert-manager"
  chart = "stable/cert-manager"
  version = "v0.5.2"
  namespace = "kube-system"  
  
  set = [
    {
      name  = "ingressShim.defaultIssuerName"
      value = "${local.letsencrypt_environment}"
    },
    {
      name  = "ingressShim.defaultIssuerKind"
      value = "ClusterIssuer"
    }
  ]
}

data "template_file" "cert_manager" {
  template = "${file("${path.module}/cluster-issuer.tpl")}"
  vars = {    
    letsencrypt_environment = "${local.letsencrypt_environment}"
    acme_server = "${local.acme_server}"
    issuer_email = "${var.issuer_email}"    
  }
}

resource "null_resource" "cert_manager_cluster_issuer_apply" {
  depends_on = ["helm_release.cert_manager"]

  provisioner "local-exec" {
      command = "echo '${data.template_file.cert_manager.rendered}' | kubectl apply -f -"
      working_dir = "${path.module}"
  }
}
