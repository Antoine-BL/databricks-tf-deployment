terraform {
  required_providers {
    azurerm = "3.73"
    random  = "~> 2.2"
    azuread = {
      source  = "hashicorp/azuread"
      version = "2.42.0"
    }
    databricks = {
      source  = "databricks/databricks"
      version = "1.42.0"
    }
  }
}

data "azuread_domains" "databricksad" {
  only_initial = true
}

//Providers setup
provider "azurerm" {
  features {}
}

provider "azuread" {
  tenant_id = var.az_tenant_id
}

provider "databricks" {
  alias      = "azure_account"
  host       = "https://accounts.azuredatabricks.net"
  account_id = var.az_databricks_account_id
  # client_id     = var.az_client_id
  # client_secret = var.az_client_secret
  auth_type = "azure-cli"
}

provider "databricks" {
  alias = "workspace"
  host = azurerm_databricks_workspace.this.workspace_url
}

//Databricks
data "azurerm_client_config" "current" {
}

locals {
  prefix = var.databricks_prefix
  tags = {
    Environment = "Demo"
    Owner       = var.az_ad_user
  }
}

resource "azurerm_resource_group" "this" {
  name     = "${local.prefix}-rg"
  location = var.region
  tags     = local.tags
}

resource "azurerm_databricks_workspace" "this" {
  name                        = "${local.prefix}-workspace"
  resource_group_name         = azurerm_resource_group.this.name
  location                    = azurerm_resource_group.this.location
  sku                         = "premium"
  managed_resource_group_name = "${local.prefix}-workspace-rg"
  tags                        = local.tags
}

output "databricks_host" {
  value = "https://${azurerm_databricks_workspace.this.workspace_url}/"
}

//Azure AD
resource "azuread_user" "admin_user" {
  user_principal_name = "admin@antoinebrassardgmail.onmicrosoft.com"
  display_name        = "Admin User"
  password            = var.az_default_password
}

resource "azuread_group" "databricks_admins" {
  display_name = "Databricks Admins"
  members= [azuread_user.admin_user.object_id]
  security_enabled = true
}

data "azuread_application_template" "scim" {
  display_name = "Azure Databricks SCIM Provisioning Connector"
}

resource "random_uuid" "uuid" {}

resource "azuread_application" "scim" {
  display_name = "spa-analytics-dbx-provisioning"
  template_id  = data.azuread_application_template.scim.template_id

  app_role {
    allowed_member_types = ["Application", "User"]
    description          = "Users can perform limited actions"
    display_name         = "User"
    enabled              = true
    id                   = random_uuid.uuid.result
    value                = "User"
  }
}

data "azuread_service_principal" "scim" {
  application_id = azuread_application.scim.application_id
}

resource "azuread_app_role_assignment" "scim" {
  app_role_id         = data.azuread_service_principal.scim.app_role_ids["User"]
  principal_object_id = azuread_group.databricks_admins.object_id
  resource_object_id  = data.azuread_service_principal.scim.object_id
}

resource "time_rotating" "scim_pat_rotate" {
  rotation_days = 365
}

resource "databricks_token" "scim_pat" {
  provider = databricks.workspace
  comment = "Terraform created for SCIM with minimum 365 days validity , (created: ${time_rotating.scim_pat_rotate.rfc3339})"
}

resource "azuread_synchronization_secret" "synchronization" {
  service_principal_id = data.azuread_service_principal.scim.id

  credential {
    key   = "BaseAddress"
    value = "https://canadacentral.azuredatabricks.net/api/2.0/preview/scim"
  }

  credential {
    key   = "SecretToken"
    value = databricks_token.scim_pat.token_value
  }

  credential {
    key   = "SyncAll"
    value = "false"
  }

  credential {
    key   = "SyncNotificationSettings"
    value = jsonencode({
      "Enabled" = "true"
      "DeleteThresholdEnabled" = false
      "Recipients" = "antoine.brassard@gmail.com"
    })
  }
}

resource "azuread_synchronization_job" "sync_job" {
  service_principal_id = data.azuread_service_principal.scim.id
  template_id          = "dataBricks"
  enabled              = true
}

resource "databricks_group" "scim_groups" {
  provider              = databricks.azure_account
  display_name          = "Databricks Admins"
  external_id           = azuread_group.databricks_admins.id
  workspace_access      = true
  databricks_sql_access = true
  allow_cluster_create = true
  allow_instance_pool_create = true
}