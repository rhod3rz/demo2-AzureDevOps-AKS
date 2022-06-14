# Get the resource group containing the firewall and firewall subnet.
data "azurerm_resource_group" "rg" {
  name  = "rg-core-01"
}
