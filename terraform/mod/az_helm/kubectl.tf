# Kubectl provider; as it's from a 3rd party must list it again in the module as well as providers block.
terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
    }
  }
}