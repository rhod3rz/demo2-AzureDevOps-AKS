# Get the 'snet-appgw' subnet id.
data "azurerm_subnet" "snet-appgw" {
  name                 = "snet-appgw"
  virtual_network_name = "vnet-prd-spoke-nteu-01"
  resource_group_name  = "rg-core-01"
}
