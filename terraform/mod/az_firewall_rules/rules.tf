# Create network rules.

resource "azurerm_firewall_network_rule_collection" "rc-net-aks-api" {
  name                = "rc-net-aks-api"
  resource_group_name = data.azurerm_resource_group.rg.name
  azure_firewall_name = var.afw_primary
  priority            = 200
  action              = "Allow"
  rule {
    name                  = "r-allow-api-udp"
    protocols             = ["UDP"]
    source_addresses      = ["*"]
    destination_addresses = ["AzureCloud.NorthEurope"]
    destination_ports     = ["1194"]
  }
  rule {
    name                  = "r-allow-api-tcp"
    protocols             = ["TCP"]
    source_addresses      = ["*"]
    destination_addresses = ["AzureCloud.NorthEurope"]
    destination_ports     = ["9000"]
  }
}

resource "azurerm_firewall_network_rule_collection" "rc-net-aks-time" {
  name                = "rc-net-aks-time"
  resource_group_name = data.azurerm_resource_group.rg.name
  azure_firewall_name = var.afw_primary
  priority            = 201
  action              = "Allow"
  rule {
    name                  = "r-allow-time"
    protocols             = ["UDP"]
    source_addresses      = ["*"]
    destination_fqdns     = ["ntp.ubuntu.com"]
    destination_ports     = ["123"]
  }
}

resource "azurerm_firewall_network_rule_collection" "rc-net-aks-dns" {
  name                = "rc-net-aks-dns"
  resource_group_name = data.azurerm_resource_group.rg.name
  azure_firewall_name = var.afw_primary
  priority            = 202
  action              = "Allow"
  rule {
    name                  = "r-allow-dns"
    protocols             = ["UDP"]
    source_addresses      = ["*"]
    destination_addresses = ["*"]
    destination_ports     = ["53"]
  }
}

resource "azurerm_firewall_network_rule_collection" "rc-net-aks-servicetags" {
  name                = "rc-net-aks-servicetags"
  resource_group_name = data.azurerm_resource_group.rg.name
  azure_firewall_name = var.afw_primary
  priority            = 203
  action              = "Allow"
  rule {
    name                  = "r-allow-servicetags"
    protocols             = ["Any"]
    source_addresses      = ["*"]
    destination_addresses = [
      "AzureActiveDirectory",
      "AzureContainerRegistry",
      "AzureKeyVault",
      "AzureMonitor",
      "MicrosoftContainerRegistry",
      "Sql"
    ]
    destination_ports     = ["*"]
  }
}

resource "azurerm_firewall_network_rule_collection" "rc-net-aks-helm" {
  name                = "rc-net-aks-helm"
  resource_group_name = data.azurerm_resource_group.rg.name
  azure_firewall_name = var.afw_primary
  priority            = 204
  action              = "Allow"
  rule {
    # Custom rule added to enable akv2k8s to install via helm.
    name                  = "r-allow-helm"
    protocols             = ["TCP"]
    source_addresses      = ["*"]
    destination_fqdns     = [
      "charts.spvapi.no",            # akv2k8s
      "raw.githubusercontent.com",   # csi-driver
      "k8s.gcr.io"                   # req for busybox to test csi-driver working
    ]
    destination_ports     = ["443"]
  }
  rule {
    # Custom rule added to prevent sni deny errors on firewall; stopping akv2k8s & csi-driver from working.
    name                  = "r-allow-sni"
    protocols             = ["TCP"]
    source_addresses      = ["*"]
    destination_addresses = ["AzureCloud.NorthEurope"]
    destination_ports     = ["443"]
  }
}

# resource "azurerm_firewall_network_rule_collection" "rc-net-aks-certmanager" {
#   name                = "rc-net-aks-certmanager"
#   resource_group_name = data.azurerm_resource_group.rg.name
#   azure_firewall_name = var.afw_primary
#   priority            = 205
#   action              = "Allow"
#   rule {
#     # Custom rule added to enable cert-manager to work; without errors pulling images and other errors communicating.
#     name                  = "r-allow-certmanager"
#     protocols             = ["TCP"]
#     source_addresses      = ["*"]
#     destination_addresses = ["AzureCloud.NorthEurope"]
#     destination_ports     = ["443"]
#   }
#   rule {
#     # Custom rule added to enable cert-manager to get to acme-staging-v02.api.letsencrypt.org.
#     name                  = "r-allow-letsencrypt"
#     protocols             = ["TCP"]
#     source_addresses      = ["*"]
#     destination_fqdns     = [
#       "acme-staging-v02.api.letsencrypt.org",
#       "quay.io"
#     ]
#     destination_ports     = ["80","443"]
#   }
# }

resource "azurerm_firewall_application_rule_collection" "rc-app-aks-servicetags" {
  name                = "rc-app-aks-servicetags"
  resource_group_name = data.azurerm_resource_group.rg.name
  azure_firewall_name = var.afw_primary
  priority            = 200
  action              = "Allow"
  rule {
    name = "r-allow-servicetags"
    source_addresses  = ["*"]
    fqdn_tags = [
      "AzureKubernetesService"
    ]
  }
}

resource "azurerm_firewall_application_rule_collection" "rc-app-aks-publicimages" {
  name                = "rc-app-aks-publicimages"
  resource_group_name = data.azurerm_resource_group.rg.name
  azure_firewall_name = var.afw_primary
  priority            = 201
  action              = "Allow"
  rule {
    name = "r-allow-dockerhub-images"
    source_addresses  = ["*"]
    target_fqdns = [
      "auth.docker.io",
      "registry-1.docker.io",
      "production.cloudflare.docker.com"
    ]
    protocol {
      port = "80"
      type = "Http"
    }
    protocol {
      port = "443"
      type = "Https"
    }
  }
}

resource "azurerm_firewall_application_rule_collection" "rc-app-bing" {
  name                = "rc-app-bing"
  resource_group_name = data.azurerm_resource_group.rg.name
  azure_firewall_name = var.afw_primary
  priority            = 301
  action              = "Allow"
  rule {
    name = "r-allow-bing"
    source_addresses  = ["*"]
    target_fqdns = [
      "*.bing.com"
    ]
    protocol {
      port = "80"
      type = "Http"
    }
    protocol {
      port = "443"
      type = "Https"
    }
  }
}

# Required if using an AKS 'LoadBalancer' service.
# resource "azurerm_firewall_nat_rule_collection" "rc-dnat-aks" {
#   name                = "rc-dnat-aks"
#   resource_group_name = data.azurerm_resource_group.rg.name
#   azure_firewall_name = var.afw_primary
#   priority            = 200
#   action              = "Dnat"
#   rule {
#     name = "r-dnat-aks"
#     source_addresses      = ["*"]
#     destination_addresses = [data.azurerm_public_ip.pi.ip_address]
#     destination_ports     = ["80"]
#     translated_port       = "80"
#     translated_address    = "20.54.106.69"
#     protocols             = ["TCP", "UDP"]
#   }
# }

# resource "azurerm_firewall_network_rule_collection" "rc-net-anyany" {
#   name                = "rc-net-anyany"
#   resource_group_name = data.azurerm_resource_group.rg.name
#   azure_firewall_name = var.afw_primary
#   priority            = 100
#   action              = "Allow"
#   rule {
#     name                  = "r-allow-anyany"
#     protocols             = ["Any"]
#     source_addresses      = ["*"]
#     destination_addresses = ["*"]
#     destination_ports     = ["*"]
#   }
# }
