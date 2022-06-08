# Create akv2k8s namespace.
resource "kubernetes_namespace" "kn-akv2k8s" {
  metadata {
    name = "akv2k8s"
  }
}

# Install akv2k8s.
resource "helm_release" "akv2k8s" {
  depends_on    = [kubernetes_namespace.kn-akv2k8s]
  name          = "akv2k8s"
  chart         = "akv2k8s"
  version       = "2.1.0"
  repository    = "https://charts.spvapi.no"
  namespace     = "akv2k8s"
  atomic        = true
}

# Create 'voting' namespace; created here to prevent destroy error if voting namespace has active pods.
resource "kubectl_manifest" "voting" {
  yaml_body = <<YAML
---
# Create 'voting' namespace; created here to prevent destroy error if voting namespace has active pods.
apiVersion: v1
kind: Namespace
metadata:
  name: voting
---
YAML
  lifecycle {
    ignore_changes = all # Ignore to prevent terraform thinking changes are needed.
  }
}

# Sync a secret from key vault into a kubernetes secret.
resource "kubectl_manifest" "akv2aks" {
  depends_on = [kubectl_manifest.voting]
  yaml_body = <<YAML
---
# Sync a secret from azure key vault into a kubernetes secret.
apiVersion: spv.no/v2beta1
kind: AzureKeyVaultSecret
metadata:
  name: certificate-sync
  namespace: voting           # The namespace to create the certs in. Certs must be in the same namespace as the resource!
spec:
  vault:
    name: kv-core-210713      # Name of key vault.
    object:
      name: rhod3rz-com       # Name of the certificate.
      type: certificate
  output:
    secret:
      name: rhod3rz-com       # Kubernetes secret name.
      type: kubernetes.io/tls # Kubernetes secret type.
---
YAML
  lifecycle {
    ignore_changes = all # Ignore to prevent terraform thinking changes are needed.
  }
}
