locals {
  frontdoor_default_hostname        = "${local.prefix_kebab}-${local.hash_suffix}.azurefd.net"
  frontend_endpoint_name_default    = "frontend-default"
}

resource "azurerm_frontdoor" "fd" {
  name                                         = "${local.prefix_kebab}-${local.hash_suffix}"
  
  resource_group_name                          = azurerm_resource_group.rg.name
  enforce_backend_pools_certificate_name_check = false

  routing_rule {
    name               = "routing-rule"
    accepted_protocols = ["Https"]
    patterns_to_match  = ["/"]
    frontend_endpoints = [local.frontend_endpoint_name_default]
    forwarding_configuration {
      forwarding_protocol = "MatchRequest"
      backend_pool_name   = "backend"
      cache_enabled       = false
    }
  }

  routing_rule {
    name               = "http-to-https-redirect"
    accepted_protocols = ["Http"]
    patterns_to_match  = ["/*"]
    frontend_endpoints = [local.frontend_endpoint_name_default]
    redirect_configuration {
      redirect_protocol = "HttpsOnly"
      custom_host       = local.frontdoor_default_hostname
      redirect_type     = "PermanentRedirect"
    }
  }

  backend_pool_load_balancing {
    name = "load-balancing"
  }

  backend_pool {
    name = "backend"
    backend {
      host_header = azurerm_app_service.webapp.default_site_hostname
      address     = azurerm_app_service.webapp.default_site_hostname
      http_port   = 80
      https_port  = 443
    }
    load_balancing_name = "load-balancing"
    health_probe_name   = "health-probe"
  }

  backend_pool_health_probe {
    name     = "health-probe"
    path     = "/"
    protocol = "Https"
  }

  frontend_endpoint {
    name                              = local.frontend_endpoint_name_default
    custom_https_provisioning_enabled = false
    host_name                         = local.frontdoor_default_hostname
  }
}
