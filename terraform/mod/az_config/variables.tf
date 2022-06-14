variable "application_code" {
  type        = string
  description = "Application code e.g. app1, app2, app3 etc."
}

variable "billing_code" {
  type        = string
  description = "Billing code e.g. 761, 762 etc."
}

variable "environment" {
  type        = string
  description = "Type of environment e.g. dev, prd, stg, uat etc."
}

variable "point_of_contact" {
  type        = string
  description = "User or distribution list e.g. admin@rh0d3rz.com"
}

variable "unique_id" {
  type        = string
  description = "A unique differentiator e.g. 220523-1752"
}

variable "region_shortname_mapping" {
  type        = map(string)
  description = "Mapping from Azure region to rhod3rz region code."
  default = {
    westeurope  = "wteu"
    northeurope = "nteu"
    eastus2     = "eus2"
    westus2     = "wus2"
    centralus   = "ceus"
  }
}

variable "location_primary" {
  type        = string
  description = "Primary location."
}

variable "location_secondary" {
  type        = string
  description = "If applicable; secondary location."
}
