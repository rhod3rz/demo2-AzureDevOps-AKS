# Get configuration.
module "az_config" {
  source                          = "../../mod/az_config"
  application_code                = var.application_code
  billing_code                    = var.billing_code
  environment                     = var.environment
  point_of_contact                = var.point_of_contact
  unique_id                       = var.unique_id
  location_primary                = var.location_primary
  location_secondary              = var.location_secondary
}

# Create resource group.
resource "azurerm_resource_group" "rg" {
  location                        = var.location_primary
  name                            = "${module.az_config.item_name.resource_group}"
  tags                            = "${module.az_config.tags}"
}

# Create access gateway.
module "az_agw" {
  source                          = "../../mod/az_agw"                                      /* The path to the module */
  location                        = var.location_primary                                    /* The location */
  resource_group_name             = azurerm_resource_group.rg.name                          /* The resource group */
  pip_agw_primary                 = "${module.az_config.item_name.pip_agw_primary}"         /* The pip name */
  agw_primary                     = "${module.az_config.item_name.agw_primary}"             /* The agw name */
}

# Create dns a record.
module "az_dns" {
  source                          = "../../mod/az_dns"                                      /* The path to the module */
  depends_on                      = [module.az_agw]                                         /* Wait for dependencies */
  record_name                     = var.environment                                         /* The a record name */
  pip_agw_primary                 = "${module.az_config.item_name.pip_agw_primary}"         /* The pip name */
}

# Create mysql server.
module "az_mysql" {
  source                          = "../../mod/az_mysql"                                    /* The path to the module */
  location                        = var.location_secondary                                  /* The location */
  resource_group_name             = azurerm_resource_group.rg.name                          /* The resource group */
  mysql_server_primary            = "${module.az_config.item_name.mysql_server_primary}"    /* MySQL name */
}

# Create kubernetes cluster.
module "az_aks" {
  source                          = "../../mod/az_aks"                                      /* The path to the module */
  depends_on                      = [module.az_agw]
  location                        = var.location_primary                                    /* The location */
  resource_group_name             = azurerm_resource_group.rg.name                          /* The resource group */
  law_primary                     = "${module.az_config.item_name.law_primary}"             /* The log analytics workspace name; must be globally unique across azure */
  aks_primary                     = "${module.az_config.item_name.aks_primary}"             /* The aks cluster name */
  gateway_id                      = module.az_agw.application_gateway_id                    /* The agw id */
}

# Create kubernetes cluster tweaks.
module "az_aks_tweaks" {
  source                          = "../../mod/az_aks_tweaks"                               /* The path to the module */
  depends_on                      = [module.az_aks]                                         /* Wait for dependencies */

  # Fix 1 - Resource group (IAM) - set 'contributor' role assignment for the 'ingressapplicationgateway' on the agw resource group; otherwise it can't manage ingress.
  # The following error is seen in ingress pod logs if not set 'E0722 13:28:17.457834 1 client.go:170] Code="ErrorApplicationGatewayForbidden"'.
  uai_name_ingress                = "ingressapplicationgateway-${module.az_aks.kc_name}"    /* The auto created 'ingressapplicationgateway' uai account */
  uai_resource_group_ingress      = "MC_${azurerm_resource_group.rg.name}_${module.az_aks.kc_name}_${var.location_primary}"  /* The auto created aks resource group */
  resource_group_id               = azurerm_resource_group.rg.id                            /* The resource group id to add IAM permissions for 'ingressgateway' */

  # Fix 2 - Resource group (IAM) - set 'acrpull' role assignment for the 'aksagentpool' on the acr; otherwise it can't pull images.
  uai_name_agent                  = "${module.az_aks.kc_name}-agentpool"                    /* The auto created 'agentpool' uai account */
  uai_resource_group_agent        = "MC_${azurerm_resource_group.rg.name}_${module.az_aks.kc_name}_${var.location_primary}"  /* The auto created aks resource group */
}

# Install helm charts.
module "az_helm" {
  source                          = "../../mod/az_helm"                                     /* The path to the module */
  depends_on                      = [module.az_aks]                                         /* Wait for dependencies */

  # Csi-driver: add 'agentpool' uami to access policies in key vault.
  uai_name_agent                  = "${module.az_aks.kc_name}-agentpool"                    /* Csi-driver: The auto created 'agentpool' uai account */
  uai_resource_group_agent        = "MC_${azurerm_resource_group.rg.name}_${module.az_aks.kc_name}_${var.location_primary}"  /* Csi-driver: The auto created aks resource group */
}
