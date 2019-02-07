resource "random_string" "app_aks_secret" {
    length = 32
    special = false    
}

resource "random_string" "app_server_secret" {
    length = 32
    special = false    
}

resource "random_string" "app_acr_push_secret" {
    length = 32
    special = false    
}

resource "null_resource" "sp" {

  triggers {
    shell_hash = "${sha256(file("${path.module}/azure-ad.sh"))}"
  }
  provisioner "local-exec" {
      command = "azure-ad.sh ${var.name} ${var.environment} ${random_string.app_aks_secret.result} ${random_string.app_server_secret.result} ${random_string.app_acr_push_secret.result}"
      interpreter = ["sh"]
      working_dir = "${path.module}"
  }
}

data "null_data_source" "depens_on_sp" {
  inputs = {
    depens_on_sp = "${null_resource.sp.triggers["shell_hash"]}"
    name = "${var.name}"
    environment = "${var.environment}"
  }
}

data "azuread_application" "adapp_aks" {  
  name = "${data.null_data_source.depens_on_sp.outputs["name"]}-aks-${data.null_data_source.depens_on_sp.outputs["environment"]}-ad-app"
}

data "azuread_service_principal" "sp_aks" {
  application_id = "${data.azuread_application.adapp_aks.application_id}"
}

data "azuread_application" "adapp_server_aks" {
  name = "${data.null_data_source.depens_on_sp.outputs["name"]}-aks-${data.null_data_source.depens_on_sp.outputs["environment"]}-server-ad-app"
}

data "azuread_application" "adapp_client_aks" {
  name = "${data.null_data_source.depens_on_sp.outputs["name"]}-aks-${data.null_data_source.depens_on_sp.outputs["environment"]}-client-ad-app"
}

data "azuread_application" "adapp_acr" {
  name = "${data.null_data_source.depens_on_sp.outputs["name"]}-acr-${data.null_data_source.depens_on_sp.outputs["environment"]}-push-ad-app"
}

data "external" "cluster_admins_group_id" {
  program = ["sh", "${path.module}/azure-ad-data.sh", "${data.null_data_source.depens_on_sp.outputs["name"]}", "${data.null_data_source.depens_on_sp.outputs["environment"]}"]
}

resource "azurerm_role_assignment" "ra_acr_aks" {
  scope                = "${var.acr_id}"
  role_definition_name = "Reader"
  principal_id         = "${data.azuread_service_principal.sp_aks.id}"
}

resource "azurerm_role_assignment" "ra_subnet_aks" {
  scope                = "${var.subnet_id}"
  role_definition_name = "Network Contributor"
  principal_id         = "${data.azuread_service_principal.sp_aks.id}"
}
