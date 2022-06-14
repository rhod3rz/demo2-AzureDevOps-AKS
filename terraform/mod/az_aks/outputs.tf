output "kc_config"       { value = azurerm_kubernetes_cluster.kc.kube_admin_config }
output "kc_name"         { value = azurerm_kubernetes_cluster.kc.name }
output "kc_rg"           { value = azurerm_kubernetes_cluster.kc.resource_group_name }
output "kc_principal_id" { value = azurerm_kubernetes_cluster.kc.identity[0].principal_id }
output "kc_tenant_id"    { value = azurerm_kubernetes_cluster.kc.identity[0].tenant_id }

