# Get the resource group that will contain the firewall and firewall subnet.
data "azurerm_resource_group" "rg" {
  name  = "rg-core-01"
}

# Get the 'AzureFirewallSubnet' id.
data "azurerm_subnet" "AzureFirewallSubnet" {
  name                 = "AzureFirewallSubnet"
  virtual_network_name = "vnet-prd-hub-nteu-01"
  resource_group_name  = "rg-core-01"
}

# Get the 'snet-aks1' subnet id.
data "azurerm_subnet" "snet-aks1" {
  name                 = "snet-aks1"
  virtual_network_name = "vnet-prd-spoke-nteu-01"
  resource_group_name  = "rg-core-01"
}
