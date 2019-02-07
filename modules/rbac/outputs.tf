output "app_aks_id" {
  value = "${data.azuread_application.adapp_aks.application_id}"
}

output "app_aks_secret" {
  value = "${random_string.app_aks_secret.result}"
}

output "sp_aks_id" {
  value = "${data.azuread_service_principal.sp_aks.id}"
}

output "app_server_id" {
  value = "${data.azuread_application.adapp_server_aks.application_id}"
}

output "app_server_secret" {
  value = "${random_string.app_server_secret.result}"
}

output "app_client_id" {
  value = "${data.azuread_application.adapp_client_aks.application_id}"
}

output "app_acr_id" {
  value = "${data.azuread_application.adapp_acr.application_id}"
}

output "app_acr_secret" {
  value = "${random_string.app_acr_push_secret.result}"
}

output "cluster_admins_group_id" {
  value = "${data.external.cluster_admins_group_id.result["id"]}"
}
