variable "uai_name_agent" {}
variable "uai_resource_group_agent" {}

# Get the key vault object; id required.
data "azurerm_key_vault" "kv" {
  name                = "kv-core-210713"
  resource_group_name = "rg-core-01"
}

# Get the current client config; tenant_id required.
data "azurerm_client_config" "current" {}

# Get the aks '...-agentpool' uami object; principal_id required.
data "azurerm_user_assigned_identity" "uai_aks" {
  name                = var.uai_name_agent
  resource_group_name = var.uai_resource_group_agent
}
output "agentpool_client_id" { value = data.azurerm_user_assigned_identity.uai_aks.client_id }

# Key vault access policy - add auto-created aks agentpool uami to key vault access policy to allow secret retrival.
resource "azurerm_key_vault_access_policy" "kvap" {
  key_vault_id             = data.azurerm_key_vault.kv.id
  tenant_id                = data.azurerm_client_config.current.tenant_id
  object_id                = data.azurerm_user_assigned_identity.uai_aks.principal_id
  key_permissions = [
    "Get",
  ]
  secret_permissions = [
    "Get",
  ]
  certificate_permissions = [
    "Get",
  ]
}

# Install csi-driver.
resource "helm_release" "csi-driver" {
  name          = "csi"
  chart         = "csi-secrets-store-provider-azure"
  version       = "0.2.1"
  repository    = "https://raw.githubusercontent.com/Azure/secrets-store-csi-driver-provider-azure/master/charts"
  namespace     = "kube-system"
  atomic        = true
  set {
    name  = "secrets-store-csi-driver.syncSecret.enabled" # Required if wanting to create env var's from secrets.
    value = "true"
  }
}

# Create a SecretProviderClass to pull secrets from key vault.
resource "kubectl_manifest" "csi-driver" {
  depends_on = [helm_release.csi-driver]
  yaml_body = <<YAML
# Create a SecretProviderClass to pull secrets from key vault.
apiVersion: secrets-store.csi.x-k8s.io/v1alpha1
kind: SecretProviderClass
metadata:
  name: kv-core-210713
  namespace: voting
spec:
  provider: azure
  secretObjects:                                                   # section required if creating env var's
  - secretName: voting
    type: Opaque
    data:
    - objectName: KV-SQL-ADMIN-PASSWORD
      key: MYSQL_PASSWORD
  parameters:
    usePodIdentity: "false"
    useVMManagedIdentity: "true"
    userAssignedIdentityID: "${data.azurerm_user_assigned_identity.uai_aks.client_id}" # identityProfile.kubeletidentity.clientId
    keyvaultName: "kv-core-210713"
    objects: |
      array:
        - |
          objectName: KV-SQL-ADMIN-PASSWORD
          objectType: secret
          objectVersion: ""
    tenantId: "73578441-dc3d-4ecd-a298-fc5c6f40e191"
YAML
  lifecycle {
    ignore_changes = all # Ignore to prevent terraform thinking changes are needed.
  }
}
