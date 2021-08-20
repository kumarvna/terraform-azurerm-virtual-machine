#----------------------------------------------------------
# Resource Group, VNet, Subnet selection & Random Resources
#----------------------------------------------------------
data "azurerm_subnet" "snet" {
  name                 = var.subnet_name
  virtual_network_name = var.virtual_network_name
  resource_group_name  = var.virtual_network_resource_group_name
}

data "azurerm_log_analytics_workspace" "logws" {
  count               = var.log_analytics_workspace_name != null ? 1 : 0
  provider            = azurerm.shared
  name                = var.log_analytics_workspace_name
  resource_group_name = var.log_analytics_workspace_rg
}

data "azurerm_backup_policy_vm" "this" {
  count               = var.backup_enabled == true ? 1 : 0
  name                = var.backup_settings.policy_name
  recovery_vault_name = var.backup_settings.vault_name
  resource_group_name = var.backup_settings.vault_rg
}