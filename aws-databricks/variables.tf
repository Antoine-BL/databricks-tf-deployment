variable "client_id" {
    description = "The OAuth client ID for the Databricks account"
    type        = string
    sensitive   = true
}
variable "client_secret" {
    description = "The OAuth client secret for the Databricks account"
    type        = string
    sensitive   = true
}
variable "databricks_account_id" {
    description = "The Databricks account ID"
    type        = string
    sensitive = true
}

variable "tags" {
  default = {}
}

variable "cidr_block" {
  default = "10.4.0.0/16"
}

variable "region" {
  default = "ca-central-1"
}

resource "random_string" "naming" {
  special = false
  upper   = false
  length  = 6
}

locals {
  prefix = "demo${random_string.naming.result}"
}