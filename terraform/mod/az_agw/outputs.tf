output "pip_ip_address_agw"              { value = azurerm_public_ip.pip.ip_address }
output "pip_id_agw"                      { value = azurerm_public_ip.pip.id }

output "application_gateway_id"          { value = azurerm_application_gateway.ag.id }
