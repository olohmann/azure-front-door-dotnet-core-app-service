output "app_service_deploy" {
    value = "az webapp deployment source config-zip --resource-group ${azurerm_app_service.webapp.resource_group_name} --name ${azurerm_app_service.webapp.name} --src app.zip"
}