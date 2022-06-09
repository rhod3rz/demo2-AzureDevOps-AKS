terraform {
  required_version = "1.2.2"                                  /* Version pin terraform; test upgrades */
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.9.0"                                       /* Version pin provider (https://releases.hashicorp.com/); test upgrades */
    }
    kubectl = {
      source  = "gavinbunney/kubectl"                         /* Preview provider to enable deploying manifest files */
      version = "1.14.0"
    }
  }
  backend "azurerm" {
    storage_account_name  = "sadlterraformstate210713"        /**** UPDATE HERE ****/
    container_name        = "tfstate-stg"                     /**** UPDATE HERE ****/
    key                   = "220606-1000-voteapp.tfstate"     /**** UPDATE HERE ****/
    # access_key          = Use $env:ARM_ACCESS_KEY or ARM_ACCESS_KEY if bash
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  client_id       = "2aa9eba7-3055-4546-b8f2-ce10f98981d2"
  subscription_id = "2bc7b65e-18d6-42ae-afb2-e66d50be6b05"
  tenant_id       = "73578441-dc3d-4ecd-a298-fc5c6f40e191"
  # client_secret = Use $env:ARM_CLIENT_SECRET or ARM_CLIENT_SECRET if bash
}

provider "kubernetes" {
  host                     = module.az_aks.kc_config.0.host
  username                 = module.az_aks.kc_config.0.username
  password                 = module.az_aks.kc_config.0.password
  client_certificate       = "${base64decode(module.az_aks.kc_config.0.client_certificate)}"
  client_key               = "${base64decode(module.az_aks.kc_config.0.client_key)}"
  cluster_ca_certificate   = "${base64decode(module.az_aks.kc_config.0.cluster_ca_certificate)}"
}

provider "helm" {
  kubernetes {
    host                   = module.az_aks.kc_config.0.host
    client_certificate     = "${base64decode(module.az_aks.kc_config.0.client_certificate)}"
    client_key             = "${base64decode(module.az_aks.kc_config.0.client_key)}"
    cluster_ca_certificate = "${base64decode(module.az_aks.kc_config.0.cluster_ca_certificate)}"
  }
}

provider "kubectl" {
  host                     = module.az_aks.kc_config.0.host
  username                 = module.az_aks.kc_config.0.username
  password                 = module.az_aks.kc_config.0.password
  client_certificate       = "${base64decode(module.az_aks.kc_config.0.client_certificate)}"
  client_key               = "${base64decode(module.az_aks.kc_config.0.client_key)}"
  cluster_ca_certificate   = "${base64decode(module.az_aks.kc_config.0.cluster_ca_certificate)}"
  load_config_file         = false # Required when running via ado.
}
