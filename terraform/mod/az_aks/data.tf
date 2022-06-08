# Get the 'snet-aks1' subnet id.
data "azurerm_subnet" "snet-aks1" {
  name                 = "snet-aks1"
  virtual_network_name = "vnet-prd-spoke-nteu-01"
  resource_group_name  = "rg-core-01"
}
