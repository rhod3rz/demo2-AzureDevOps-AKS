# Fix 1 - Resource group (IAM) - set 'contributor' role assignment for the 'ingressapplicationgateway' on the agw resource group; otherwise it can't manage ingress.
# The following error seen in ingress pod logs if not set 'E0722 13:28:17.457834 1 client.go:170] Code="ErrorApplicationGatewayForbidden"'.
resource "azurerm_role_assignment" "ra" {
  scope                = var.resource_group_id
  role_definition_name = "Contributor"
  principal_id         = data.azurerm_user_assigned_identity.uai.principal_id
}

# Fix 2 - Resource group (IAM) - set 'acrpull' role assignment for the 'aksagentpool' on the acr; otherwise it can't pull images.
resource "azurerm_role_assignment" "acrpull-to-aks" {
  scope                = data.azurerm_container_registry.cr.id
  role_definition_name = "AcrPull"
  principal_id         = data.azurerm_user_assigned_identity.uai_aks.principal_id
}
