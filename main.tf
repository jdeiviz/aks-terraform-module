provider "azurerm" {
  version = "~> 1.20"
}

provider "azuread" {
  version = "~> 0.1"
}

provider "random" {
  version = "~> 2.0"
}

provider "null" {
  version = "~> 2.0"
}

provider "external" {
  version = "~> 1.0" 
}

provider "template" {
  version = "~> 2.0"
}

resource "azurerm_resource_group" "rg_aks" {
  name     = "${var.name}-aks-${var.environment}-rg"
  location = "${var.location}"
  
  tags {
    component   = "aks"
    environment = "${var.environment}"
  }
}

module "subnet" {
  source = "./modules/subnet"
  
  vnet_resource_group = "${var.vnet_resource_group}"
  vnet_name = "${var.vnet_name}"
  vnet_subnet = "${var.vnet_subnet}"
}

module "acr" {
  source = "./modules/acr"

  name = "${var.name}"
  environment = "${var.environment}"
  resource_group = "${azurerm_resource_group.rg_aks.name}"
  location = "${azurerm_resource_group.rg_aks.location}"
  sku = "${var.acr_sku}"
}

module "rbac" {
  source = "./modules/rbac"

  name = "${var.name}"
  environment = "${var.environment}"
  acr_id = "${module.acr.id}"
  subnet_id = "${module.subnet.id}"
}

module "log" {
  source = "./modules/log"

  name = "${var.name}"
  environment = "${var.environment}"
  resource_group = "${azurerm_resource_group.rg_aks.name}"
  location = "${azurerm_resource_group.rg_aks.location}"
}

# aks
resource "azurerm_kubernetes_cluster" "aks" {
  name                  = "${var.name}-aks-${var.environment}"
  resource_group_name   = "${azurerm_resource_group.rg_aks.name}"
  location              = "${azurerm_resource_group.rg_aks.location}"  
  dns_prefix            = "${var.dns_prefix}"
  kubernetes_version    = "${var.kubernetes_version}"

  agent_pool_profile {
    name              = "${var.name}aks${var.environment}"
    count             = "${var.count}"
    vm_size           = "${var.vm_size}"
    max_pods          = "${var.max_pods}"
    vnet_subnet_id    = "${module.subnet.id}"
    os_type           = "${var.os_type}"
    os_disk_size_gb   = "${var.os_disk_size_gb}"
  }

  linux_profile {
    admin_username = "${var.admin_username}"

    ssh_key {
      key_data = "${file(var.ssh_key_path)}"
    }
  }

  network_profile {
    network_plugin = "azure"
  }

  service_principal {
    client_id     = "${module.rbac.app_aks_id}"
    client_secret = "${module.rbac.app_aks_secret}"
  }

  role_based_access_control {
    enabled = true
    
    azure_active_directory {
      client_app_id     = "${module.rbac.app_client_id}"
      server_app_id     = "${module.rbac.app_server_id}"
      server_app_secret = "${module.rbac.app_server_secret}"
    }    
  }

  addon_profile {
    oms_agent {
      enabled                     = true
      log_analytics_workspace_id  = "${module.log.id}"
    }
  }

  tags {
    component   = "aks"
    environment = "${var.environment}"
  }
}

resource "null_resource" "az_get_credentials" {
  depends_on = ["azurerm_kubernetes_cluster.aks"]

  triggers {
    depends_on_kubectl_credentials = "${azurerm_kubernetes_cluster.aks.fqdn}"
  }

  provisioner "local-exec" {
      command = "az aks get-credentials --resource-group ${azurerm_resource_group.rg_aks.name} --name ${var.name}-aks-${var.environment}"
      working_dir = "${path.module}"
  }
}

provider "kubernetes" {
  version = "~> 1.5"

  host                   = "${azurerm_kubernetes_cluster.aks.kube_admin_config.0.host}"
  username               = "${azurerm_kubernetes_cluster.aks.kube_admin_config.0.username}"
  password               = "${azurerm_kubernetes_cluster.aks.kube_admin_config.0.password}"
  client_certificate     = "${base64decode(azurerm_kubernetes_cluster.aks.kube_admin_config.0.client_certificate)}"
  client_key             = "${base64decode(azurerm_kubernetes_cluster.aks.kube_admin_config.0.client_key)}"
  cluster_ca_certificate = "${base64decode(azurerm_kubernetes_cluster.aks.kube_admin_config.0.cluster_ca_certificate)}"
}

resource "kubernetes_cluster_role_binding" "clusteradmins_rolebinding_aks" {
  metadata {
    name = "cluster-admins"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Group"
    name      = "${module.rbac.cluster_admins_group_id}"    
  }
}

module "azurefile" {
  source = "./modules/azurefile"

  depends_on_kubectl_credentials = "${null_resource.az_get_credentials.triggers["depends_on_kubectl_credentials"]}"
  name = "${var.name}"
  environment = "${var.environment}"
  resource_group = "${azurerm_kubernetes_cluster.aks.node_resource_group}"
  location = "${azurerm_resource_group.rg_aks.location}"  
}

module "helm" {
  source = "./modules/helm"

  name = "${var.name}"
  environment = "${var.environment}"
  resource_group = "${azurerm_kubernetes_cluster.aks.node_resource_group}"
  location = "${azurerm_resource_group.rg_aks.location}"
}

provider "helm" {
  version = "~> 0.7"

  service_account = "${module.helm.service_account}"  
  kubernetes {
    host                   = "${azurerm_kubernetes_cluster.aks.kube_admin_config.0.host}"
    username               = "${azurerm_kubernetes_cluster.aks.kube_admin_config.0.username}"
    password               = "${azurerm_kubernetes_cluster.aks.kube_admin_config.0.password}"
    client_certificate     = "${base64decode(azurerm_kubernetes_cluster.aks.kube_admin_config.0.client_certificate)}"
    client_key             = "${base64decode(azurerm_kubernetes_cluster.aks.kube_admin_config.0.client_key)}"
    cluster_ca_certificate = "${base64decode(azurerm_kubernetes_cluster.aks.kube_admin_config.0.cluster_ca_certificate)}"    
  }
}

module "ingress" {
  source = "./modules/ingress"

  name = "${var.name}"
  environment = "${var.environment}"
  resource_group = "${azurerm_kubernetes_cluster.aks.node_resource_group}"
  location = "${azurerm_resource_group.rg_aks.location}"
}

module "certmanager" {
  source = "./modules/certmanager"

  depends_on_kubectl_credentials = "${null_resource.az_get_credentials.triggers["depends_on_kubectl_credentials"]}"
  name = "${var.name}"
  environment = "${var.environment}"
  resource_group = "${azurerm_kubernetes_cluster.aks.node_resource_group}"
  location = "${azurerm_resource_group.rg_aks.location}"
  issuer_email = "${var.cert_issuer_email}"
}
