locals {
  app_service_name = "${local.prefix_kebab}-${local.hash_suffix}"
  app_service_fqdn = "${local.prefix_kebab}-${local.hash_suffix}.azurewebsites.net"
}

resource "azurerm_app_service_plan" "sp" {
  name                = "${local.prefix_kebab}-asp"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  kind                = "Linux"

  reserved = true

  sku {
    tier = "Standard"
    size = "S1"
  }
}

resource "azurerm_app_service" "webapp" {
  name                = local.app_service_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  app_service_plan_id = azurerm_app_service_plan.sp.id
  https_only          = true

  app_settings = {
    AzureAd__Domain                     = local.frontdoor_default_hostname
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = false
    DOCKER_REGISTRY_SERVER_URL          = "https://${azurerm_container_registry.acr.name}.azurecr.io"
    DOCKER_REGISTRY_SERVER_USERNAME     = azurerm_container_registry.acr.admin_username
    DOCKER_REGISTRY_SERVER_PASSWORD     = azurerm_container_registry.acr.admin_password
    X_AZURE_FDID                        = azurerm_frontdoor.fd.header_frontdoor_id
    WEBSITES_PORT                       = "8080"
  }

  site_config {
    linux_fx_version = "DOCKER|nginx"
    always_on        = true
    http2_enabled    = true
    ftps_state       = "Disabled"

    // IP Restrictions for Azure Front Door: https://docs.microsoft.com/en-us/azure/frontdoor/front-door-faq#how-do-i-lock-down-the-access-to-my-backend-to-only-azure-front-door
    ip_restriction {
      ip_address = "147.243.0.0/16"
    }

    ip_restriction {
      ip_address = "2a01:111:2050::/44"
    }

    ip_restriction {
      ip_address = "168.63.129.16/32"
    }

    ip_restriction {
      ip_address = "169.254.169.254/32"
    }
  }

  lifecycle {
    ignore_changes = [site_config[0].linux_fx_version]
  }
}
