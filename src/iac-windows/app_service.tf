locals {
  app_service_name = "${local.prefix_kebab}-${local.hash_suffix}"
  app_service_fqdn = "${local.prefix_kebab}-${local.hash_suffix}.azurewebsites.net"
}

resource "azurerm_app_service_plan" "sp" {
  name                = "${local.prefix_kebab}-asp"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  kind                = "Windows"

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
      "WEBSITE_RUN_FROM_PACKAGE" = "1"
      "X-Azure-FDID" = azurerm_frontdoor.fd.header_frontdoor_id 
  }

  site_config {
    always_on                = true
    http2_enabled            = true
    ftps_state               = "Disabled"

    // IP Restrictions for Azure Front Door: https://docs.microsoft.com/en-us/azure/frontdoor/front-door-faq#how-do-i-lock-down-the-access-to-my-backend-to-only-azure-front-door
    ip_restriction {
      ip_address  = "147.243.0.0/16"
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
}
