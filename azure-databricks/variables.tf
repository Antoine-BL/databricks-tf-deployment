variable "region" {
  type    = string
  default = "canadacentral"
}

variable "databricks_prefix" {
  type    = string
  default = "antoinedatabrickstest1234"
}

variable "az_tenant_id" {
    description = "Azure AD Tenant ID"
    type        = string
    sensitive = true
}

variable "az_ad_user" {
    description = "Azure AD username"
    type        = string
    sensitive = true
}

variable "az_databricks_account_id" {
    description = "The Databricks account ID"
    type        = string
    sensitive = true
}


variable "az_client_id" {
    description = "The OAuth client ID for the Databricks account"
    type        = string
    sensitive   = true
}

variable "az_client_secret" {
    description = "The OAuth client secret for the Databricks account"
    type        = string
    sensitive   = true
}

variable "az_default_password" {
    description = "The OAuth client secret for the Databricks account"
    type        = string
    sensitive   = true
}