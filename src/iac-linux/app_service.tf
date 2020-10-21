resource "azurerm_app_service_plan" "sp" {
  name                = "${local.prefix_kebab}-asp"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  kind                = "Linux"

  sku {
    tier = "Standard"
    size = "S1"
  }

  reserved = true # Mandatory for Linux plans
}

resource "azurerm_app_service" "webapp" {
  name                = "${local.prefix_kebab}-${local.hash_suffix}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  app_service_plan_id = azurerm_app_service_plan.sp.id
  https_only          = true

  app_settings = {
      "WEBSITE_RUN_FROM_PACKAGE" = "1"
  }

  site_config {
    always_on                = true
    http2_enabled            = true
    ftps_state               = "Disabled"
  }
}
