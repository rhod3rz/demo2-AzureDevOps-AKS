# Create log analytics workspace.
resource "azurerm_log_analytics_workspace" "law" {
  location                    = var.location
  resource_group_name         = var.resource_group_name
  name                        = var.law_primary
  sku                         = "PerGB2018"
}

# Create log analytics solution.
resource "azurerm_log_analytics_solution" "las" {
  location                    = var.location
  resource_group_name         = var.resource_group_name
  solution_name               = "ContainerInsights"
  workspace_resource_id       = azurerm_log_analytics_workspace.law.id
  workspace_name              = azurerm_log_analytics_workspace.law.name
  plan {
      publisher = "Microsoft"
      product   = "OMSGallery/ContainerInsights"
  }
}

# Create aks cluster.
resource "azurerm_kubernetes_cluster" "kc" {
  location                    = var.location
  resource_group_name         = var.resource_group_name
  name                        = var.aks_primary
  dns_prefix                  = "${var.aks_primary}-dns"

  default_node_pool {
    name                      = "default"
    enable_auto_scaling       = true
    min_count                 = "1"
    max_count                 = "3"
    vm_size                   = "Standard_D2as_v4"
    max_pods                  = "30"
    type                      = "VirtualMachineScaleSets"
    vnet_subnet_id            = data.azurerm_subnet.snet-aks1.id # Nodes and pods will receive ip's from here 'snet-aks1 (10.94.110.0/23)'.
  }

  # IMPORTANT: When this was set to Service Principal, the sp had to have the 'Network Contributor' role on the vNet (vnet-prd-spoke-nteu-01).
  # After changing to SystemAssigned uami, that no longer appears to be a requirement.
  identity {
    type = "SystemAssigned"
  }

  # Enable aad integration and rbac.
  azure_active_directory_role_based_access_control {
    managed                = true
    admin_group_object_ids = ["a11b9012-e930-4801-bb3a-1a46e42b830a"]
    azure_rbac_enabled     = true
  }

  network_profile {
    network_plugin            = "azure"
    service_cidr              = "172.16.0.0/24"                # Internal ip range used by cluster services.
    dns_service_ip            = "172.16.0.10"
    docker_bridge_cidr        = "172.17.0.1/16"
    outbound_type             = "userDefinedRouting"           # Force all egress traffic to go via afw.
  }

  # Install AGIC (application gateway ingress controller).
  ingress_application_gateway {
    gateway_id = var.gateway_id
  }

  # Install log analytics agent.
  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  }

  lifecycle {
    ignore_changes = [
      default_node_pool.0.node_count, # Ignore due to auto-scaling.
      # kube_admin_config,              # Ignore due to tf wanting to recreate the cluster on every run.
      # kube_config                     # Ignore due to tf wanting to recreate the cluster on every run.
    ]
  }

}
