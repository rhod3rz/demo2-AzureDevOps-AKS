# Create public ip; MUST be created in the same resource group that contains the 'AzureFirewallSubnet'.
resource "azurerm_public_ip" "pip" {
  location                 = data.azurerm_resource_group.rg.location
  resource_group_name      = data.azurerm_resource_group.rg.name
  name                     = var.pip_afw_primary
  allocation_method        = "Static"
  sku                      = "Standard"
}

# Create azure firewall; MUST be created in the same resource group that contains the 'AzureFirewallSubnet'.
resource "azurerm_firewall" "fw" {
  location                 = data.azurerm_resource_group.rg.location
  resource_group_name      = data.azurerm_resource_group.rg.name
  name                     = var.afw_primary
  sku_name                 = "AZFW_VNet"
  sku_tier                 = "Standard"
  ip_configuration {
    name                   = "fw-ip-config-01"
    subnet_id              = data.azurerm_subnet.AzureFirewallSubnet.id
    public_ip_address_id   = azurerm_public_ip.pip.id
  }
}

# Enable dns proxy; required for firewall rules.
resource "null_resource" "r1" {
  depends_on = [azurerm_firewall.fw]
  provisioner "local-exec" {
    command = <<COMMAND
      az login --service-principal --username $ARM_CLIENT_ID --password $ARM_CLIENT_SECRET --tenant $ARM_TENANT_ID
      az extension add --name azure-firewall
      az network firewall update --name ${var.afw_primary} --resource-group ${data.azurerm_resource_group.rg.name} --enable-dns-proxy true
    COMMAND
    interpreter=["/bin/bash", "-c"]
  }
}

# Create route table (udr for aks subnet to force traffic via firewall); MUST be created in the same resource group that contains the 'AzureFirewallSubnet'.
resource "azurerm_route_table" "rt" {
  location                 = data.azurerm_resource_group.rg.location
  resource_group_name      = data.azurerm_resource_group.rg.name
  name                     = var.rt_name
  disable_bgp_route_propagation = false
  route {
    name                   = var.rtr_name_virtual_appliance
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.fw.ip_configuration[0].private_ip_address
  }
  route {
    name                   = var.rtr_name_internet
    address_prefix         = "${azurerm_public_ip.pip.ip_address}/32"
    next_hop_type          = "Internet"
  }
}

# Associate route table with aks subnet.
resource "azurerm_subnet_route_table_association" "srta" {
  subnet_id                = data.azurerm_subnet.snet-aks1.id
  route_table_id           = azurerm_route_table.rt.id
}
