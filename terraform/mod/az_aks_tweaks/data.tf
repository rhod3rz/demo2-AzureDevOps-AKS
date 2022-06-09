# Fix 1 - Resource group (IAM) - set 'contributor' role assignment for the 'ingressapplicationgateway' on the agw resource group; otherwise it can't manage ingress.
# The following error seen in ingress pod logs if not set 'E0722 13:28:17.457834 1 client.go:170] Code="ErrorApplicationGatewayForbidden"'.
# Get the agic 'ingressapplicationgateway...' uami object; principal_id required.
data "azurerm_user_assigned_identity" "uai" {
  name                = var.uai_name_ingress
  resource_group_name = var.uai_resource_group_ingress
}

# Fix 2 - Resource group (IAM) - set 'acrpull' role assignment for the 'aksagentpool' on the acr; otherwise it can't pull images.
# Get the acr details.
data "azurerm_container_registry" "cr" {
  name                = "acrdlnteudemoapps210713"
  resource_group_name = "rg-core-01"
}
# Get the aks '...-agentpool' uami object; principal_id required.
data "azurerm_user_assigned_identity" "uai_aks" {
  name                = var.uai_name_agent
  resource_group_name = var.uai_resource_group_agent
}
