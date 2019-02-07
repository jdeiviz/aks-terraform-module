
resource "azurerm_storage_account" "azurefile" {
  name                     = "${var.name}aks${var.environment}af"
  resource_group_name      = "${var.resource_group}"
  location                 = "${var.location}"  
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags {
    component   = "aks"
    environment = "${var.environment}"
  }
}

resource "null_resource" "azurefile" {
  
  provisioner "local-exec" {
      command = "kubectl apply -f cluster-role.yaml"
      working_dir = "${path.module}"
  }
}

resource "kubernetes_storage_class" "azurefile" {
  metadata {
    name = "azurefile"
  }

  storage_provisioner = "kubernetes.io/azure-file"
  reclaim_policy = "Delete"

  parameters {
    skuName = "Standard_LRS"
    location = "${var.location}"
    storageAccount = "${azurerm_storage_account.azurefile.name}"
  }
}
