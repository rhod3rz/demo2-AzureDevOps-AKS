output "pip_ip_address_afw"      { value = azurerm_public_ip.pip.ip_address }
output "pip_id_afw"              { value = azurerm_public_ip.pip.id }

output "fw_name"                 { value = azurerm_firewall.fw.name }
output "fw_ip_configuration"     { value = azurerm_firewall.fw.ip_configuration }
