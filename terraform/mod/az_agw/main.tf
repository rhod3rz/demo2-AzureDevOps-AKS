resource "azurerm_public_ip" "pip" {
  location            = var.location
  resource_group_name = var.resource_group_name
  name                = var.pip_agw_primary
  allocation_method   = "Static"
  sku                 = "Standard"
}

locals {
  backend_address_pool_name      = "voteapp-beap"
  frontend_port_name             = "voteapp-feport"
  frontend_ip_configuration_name = "voteapp-feip"
  http_setting_name              = "voteapp-be-htst"
  listener_name                  = "voteapp-httplstn"
  request_routing_rule_name      = "voteapp-rqrt"
  redirect_configuration_name    = "voteapp-rdrcfg"
}

resource "azurerm_application_gateway" "ag" {
  location            = var.location
  resource_group_name = var.resource_group_name
  name                = var.agw_primary
  enable_http2        = true

  sku {
    name     = "WAF_v2" # Standard_v2 or WAF_v2
    tier     = "WAF_v2" # Standard_v2 or WAF_v2
    capacity = 1
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = data.azurerm_subnet.snet-appgw.id
  }

  # --------------------- #
  # --- Shared Config --- #
  # --------------------- #
  # This creates the 'public' frontend; an alternative option is private. If created via the portal it is auto-named.
  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.pip.id
  }

  # ----------------- #
  # --- 80 Config --- #
  # ----------------- #
  # The routing rule that combines (1) the listener, (2) the backend pool and (3) the http settings.
  request_routing_rule {
    name                       = local.request_routing_rule_name
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
    priority                   = "100"
  }

  # 1. The 'listener' config.
  frontend_port {
    name = local.frontend_port_name
    port = 80
  }
  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  # 2. The 'backend pool' config.
  backend_address_pool {
    name = local.backend_address_pool_name
  }

  # 3. The 'http settings' config (aka how AGW will communicate with the backend pool e.g. 80 or 443 if E2E TLS is required).
  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  waf_configuration {
    enabled                     = true
    firewall_mode               = "Prevention"
    rule_set_type               = "OWASP"
    rule_set_version            = "3.1"
  }

  # Ignore most changes as they will be managed manually.
  lifecycle {
    ignore_changes = [
      backend_address_pool,
      backend_http_settings,
      frontend_port,
      http_listener,
      probe,
      request_routing_rule,
      url_path_map,
      ssl_certificate,
      redirect_configuration,
      autoscale_configuration,
      tags
    ]
  }

}
