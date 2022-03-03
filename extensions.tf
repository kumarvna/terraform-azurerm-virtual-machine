#For a list of available VM extensions run "az vm extension image list --location westeurope --output table"

#--------------------------------------------------------------
# Guest Configuration Agent Installation for windows
#--------------------------------------------------------------
resource "azurerm_virtual_machine_extension" "guestsagentwin" {
  count = var.os_flavor == "windows" ? 1 : 0

  name                       = "GuestConfigurationAgentForWindows"
  virtual_machine_id         = azurerm_windows_virtual_machine.win_vm[count.index].id
  publisher                  = "Microsoft.GuestConfiguration"
  type                       = "ConfigurationforWindows"
  type_handler_version       = "1.29"
  auto_upgrade_minor_version = true

  lifecycle {
    ignore_changes = [tags]
  }
}

#--------------------------------------------------------------
# Guest Configuration Agent Installation for Linux
#--------------------------------------------------------------
resource "azurerm_virtual_machine_extension" "guestsagentlinux" {
  count = var.os_flavor == "linux" ? 1 : 0

  name                       = "GuestConfigurationAgentForLinux"
  virtual_machine_id         = azurerm_linux_virtual_machine.linux_vm[count.index].id
  publisher                  = "Microsoft.GuestConfiguration"
  type                       = "ConfigurationforWindows"
  type_handler_version       = "1.26"
  auto_upgrade_minor_version = true

  lifecycle {
    ignore_changes = [tags]
  }
}

#--------------------------------------------------------------
# Azure Log Analytics Workspace Agent Installation for windows
#--------------------------------------------------------------
resource "azurerm_virtual_machine_extension" "omsagentwin" {
  count = var.log_analytics_workspace_name != null && var.os_flavor == "windows" ? 1 : 0

  name                       = "OmsAgentForWindows"
  virtual_machine_id         = azurerm_windows_virtual_machine.win_vm[count.index].id
  publisher                  = "Microsoft.EnterpriseCloud.Monitoring"
  type                       = "MicrosoftMonitoringAgent"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
    {
      "workspaceId": "${data.azurerm_log_analytics_workspace.logws.0.workspace_id}"
    }
  SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
    {
    "workspaceKey": "${data.azurerm_log_analytics_workspace.logws.0.primary_shared_key}"
    }
  PROTECTED_SETTINGS

  lifecycle {
    ignore_changes = [tags]
  }
}

#--------------------------------------------------------------
# Azure Log Analytics Workspace Agent Installation for Linux
#--------------------------------------------------------------
resource "azurerm_virtual_machine_extension" "omsagentlinux" {
  count = var.log_analytics_workspace_name != null && var.os_flavor == "linux" ? 1 : 0

  name                       = "OmsAgentForLinux"
  virtual_machine_id         = azurerm_linux_virtual_machine.linux_vm[count.index].id
  publisher                  = "Microsoft.EnterpriseCloud.Monitoring"
  type                       = "OmsAgentForLinux"
  type_handler_version       = "1.13"
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
    {
      "workspaceId": "${data.azurerm_log_analytics_workspace.logws.0.workspace_id}"
    }
  SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
    {
    "workspaceKey": "${data.azurerm_log_analytics_workspace.logws.0.primary_shared_key}"
    }
  PROTECTED_SETTINGS

  lifecycle {
    ignore_changes = [tags]
  }
}

#---------------------------------------
# Domain Join for Windows Virtual Machine
#---------------------------------------
resource "azurerm_virtual_machine_extension" "domjoin" {
  count = var.ad_domain_name != null && var.os_flavor == "windows" ? 1 : 0

  name                 = "DomainJoin"
  virtual_machine_id   = azurerm_windows_virtual_machine.win_vm[count.index].id
  publisher            = "Microsoft.Compute"
  type                 = "JsonADDomainExtension"
  type_handler_version = "1.3"

  settings           = <<SETTINGS
  {
  "Name": "${var.ad_domain_name}",
  "OUPath": "${var.oupath}",
  "Restart": "true",
  "Options": "3",
  "User": "${var.ad_user_name}"
  }
  SETTINGS
  protected_settings = <<PROTECTED_SETTINGS
  {
  "Password": "${var.ad_user_password}"
  }
  PROTECTED_SETTINGS

  lifecycle {
    ignore_changes = [tags]
  }

  depends_on = [azurerm_windows_virtual_machine.win_vm]
}

#---------------------------------------
# Azure DSC onboarding and Baseline configuration for Windows Virtual Machine
#---------------------------------------
resource "azurerm_virtual_machine_extension" "AzureDSC" {
  count = var.ad_domain_name != null && var.os_flavor == "windows" ? 1 : 0

  name                       = "AzureDSC"
  virtual_machine_id         = azurerm_windows_virtual_machine.win_vm[count.index].id
  publisher                  = "Microsoft.Powershell"
  type                       = "DSC"
  type_handler_version       = "2.77"
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
  {
    "WmfVersion": "latest",
    "ModulesUrl": "${var.dsc_modulesurl}",
    "SASToken": "${var.dsc_sastoken}",
    "ConfigurationFunction": "RegistrationMetaConfigV2.ps1\\RegistrationMetaConfigV2",
    "Privacy": {
      "DataCollection": ""
    },
    "Properties": {
      "RegistrationKey": {
      "UserName": "PLACEHOLDER_DONOTUSE",
      "Password": "PrivateSettingsRef:registrationKeyPrivate"
      },
      "RegistrationUrl" : "${var.dsc_endpoint}",
      "NodeConfigurationName" : "${var.dsc_config}",
      "ConfigurationMode": "${var.dsc_mode}",
      "RefreshFrequencyMins": 30,
      "ConfigurationModeFrequencyMins": 15,
      "RebootNodeIfNeeded": true,
      "ActionAfterReboot": "continueConfiguration",
      "AllowModuleOverwrite": true
    }
  }
  SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
  {
    "Items": {
      "registrationKeyPrivate": "${var.dsc_key}"
    }
  }
  PROTECTED_SETTINGS

  lifecycle {
    ignore_changes = [tags]
  }

  depends_on = [azurerm_windows_virtual_machine.win_vm, azurerm_virtual_machine_extension.domjoin]
}
