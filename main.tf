locals {
  nsg_inbound_rules = { for idx, security_rule in var.nsg_inbound_rules : security_rule.name => {
    idx : idx,
    security_rule : security_rule,
    }
  }

  vm_data_disks = { for idx, data_disk in var.data_disks : data_disk.name => {
    idx : idx,
    data_disk : data_disk,
    }
  }
}

#---------------------------------------------------------------
# Generates SSH2 key Pair for Linux VM's (Dev Environment only)
#---------------------------------------------------------------
resource "tls_private_key" "rsa" {
  count     = var.generate_admin_ssh_key == true && var.os_flavor == "linux" ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "random_password" "passwd" {
  count       = var.disable_password_authentication != true || var.os_flavor == "windows" && var.admin_password == null ? 1 : 0
  length      = 24
  min_upper   = 4
  min_lower   = 2
  min_numeric = 4
  special     = false

  keepers = {
    admin_password = var.os_flavor
  }
}

resource "random_string" "str" {
  count   = var.enable_public_ip_address == true ? 1 : 0
  length  = 6
  special = false
  upper   = false
  keepers = {
    domain_name_label = var.virtual_machine_name
  }
}

#-----------------------------------
# Public IP for Virtual Machine
#-----------------------------------
resource "azurerm_public_ip" "pip" {
  count               = var.enable_public_ip_address == true ? 1 : 0
  name                = lower("pip-vm-${var.virtual_machine_name}-${data.azurerm_resource_group.rg.location}")
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = format("%s%s", lower(replace(var.virtual_machine_name, "/[[:^alnum:]]/", "")), random_string.str[0].result)
  tags                = merge({ "ResourceName" = lower("pip-vm-${var.virtual_machine_name}-${data.azurerm_resource_group.rg.location}") }, var.tags, )

  lifecycle {
    ignore_changes = [tags]
  }
}

#---------------------------------------
# Network Interface for Virtual Machine
#---------------------------------------
resource "azurerm_network_interface" "nic" {
  name                          = lower("nic-${format("vm%s", lower(replace(var.virtual_machine_name, "/[[:^alnum:]]/", "")))}")
  resource_group_name           = data.azurerm_resource_group.rg.name
  location                      = data.azurerm_resource_group.rg.location
  dns_servers                   = var.dns_servers
  enable_ip_forwarding          = var.enable_ip_forwarding
  enable_accelerated_networking = var.enable_accelerated_networking
  tags                          = merge({ "ResourceName" = lower("nic-${var.virtual_machine_name}") }, var.tags, )

  lifecycle {
    ignore_changes = [tags]
  }

  ip_configuration {
    name                          = lower("ipconfig-${format("vm%s", lower(replace(var.virtual_machine_name, "/[[:^alnum:]]/", "")))}")
    primary                       = true
    subnet_id                     = data.azurerm_subnet.snet.id
    private_ip_address_allocation = var.private_ip_address_allocation_type
    private_ip_address            = var.private_ip_address_allocation_type == "Static" ? var.private_ip_address : null
    public_ip_address_id          = var.enable_public_ip_address == true ? azurerm_public_ip.pip[0].id : null
  }
}

#---------------------------------------
# Virtual Machine Availability Set
#---------------------------------------
resource "azurerm_availability_set" "aset" {
  count                        = var.enable_vm_availability_set ? 1 : 0
  name                         = lower("avail-${var.virtual_machine_name}-${data.azurerm_resource_group.rg.location}")
  resource_group_name          = data.azurerm_resource_group.rg.name
  location                     = data.azurerm_resource_group.rg.location
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true
  tags                         = merge({ "ResourceName" = lower("avail-${var.virtual_machine_name}-${data.azurerm_resource_group.rg.location}") }, var.tags, )

  lifecycle {
    ignore_changes = [tags]
  }
}

#---------------------------------------------------------------
# Network security group for Virtual Machine Network Interface
#---------------------------------------------------------------
resource "azurerm_network_security_group" "nsg" {
  name                = lower("nsg_${var.virtual_machine_name}_${data.azurerm_resource_group.rg.location}_in")
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  tags                = merge({ "ResourceName" = lower("nsg_${var.virtual_machine_name}_${data.azurerm_resource_group.rg.location}_in") }, var.tags, )

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azurerm_network_security_rule" "nsg_rule" {
  for_each                    = local.nsg_inbound_rules
  name                        = each.key
  priority                    = 100 * (each.value.idx + 1)
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = each.value.security_rule.destination_port_range
  source_address_prefix       = each.value.security_rule.source_address_prefix
  destination_address_prefix  = element(concat(data.azurerm_subnet.snet.address_prefixes, [""]), 0)
  description                 = "Inbound_Port_${each.value.security_rule.destination_port_range}"
  resource_group_name         = data.azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
  depends_on                  = [azurerm_network_security_group.nsg]
}

resource "azurerm_network_interface_security_group_association" "nsgassoc" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

#---------------------------------------
# Virutal machine data disks
#---------------------------------------
resource "azurerm_managed_disk" "data_disk" {
  for_each             = local.vm_data_disks
  name                 = "${var.virtual_machine_name}-DataDisk_${each.value.idx}"
  location             = data.azurerm_resource_group.rg.location
  resource_group_name  = data.azurerm_resource_group.rg.name
  storage_account_type = each.value.data_disk.storage_account_type
  create_option        = "Empty"
  disk_size_gb         = each.value.data_disk.disk_size_gb
  tags                 = var.tags

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azurerm_virtual_machine_data_disk_attachment" "data_disk" {
  for_each           = local.vm_data_disks
  managed_disk_id    = azurerm_managed_disk.data_disk[each.key].id
  virtual_machine_id = var.os_flavor == "windows" ? azurerm_windows_virtual_machine.win_vm[0].id : azurerm_linux_virtual_machine.linux_vm[0].id
  lun                = each.value.idx
  caching            = "ReadWrite"
}

#---------------------------------------
# Linux Virtual machine
#---------------------------------------
resource "azurerm_linux_virtual_machine" "linux_vm" {
  count                      = var.os_flavor == "linux" ? 1 : 0
  name                       = var.virtual_machine_name
  resource_group_name        = data.azurerm_resource_group.rg.name
  location                   = data.azurerm_resource_group.rg.location
  size                       = var.virtual_machine_size
  admin_username             = var.admin_username
  admin_password             = var.disable_password_authentication != true && var.admin_password == null ? random_password.passwd[0].result : var.admin_password
  network_interface_ids      = azurerm_network_interface.nic.id
  source_image_id            = var.source_image_id != null ? var.source_image_id : null
  provision_vm_agent         = true
  allow_extension_operations = true
  custom_data                = var.custom_data != null ? var.custom_data : null
  dedicated_host_id          = var.dedicated_host_id
  availability_set_id        = var.enable_vm_availability_set == true ? azurerm_availability_set.aset[0].id : null
  tags                       = merge({ "ResourceName" = var.virtual_machine_name }, var.tags, )

  lifecycle {
    ignore_changes = [tags]
  }

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.admin_ssh_key == true && var.os_flavor == "linux" ? tls_private_key.rsa[0].public_key_openssh : var.admin_ssh_key
  }

  dynamic "source_image_reference" {
    for_each = var.source_image_id != null ? [] : [1]
    content {
      publisher = var.custom_image != null ? var.custom_image["publisher"] : var.linux_distribution_list[lower(var.linux_distribution_name)]["publisher"]
      offer     = var.custom_image != null ? var.custom_image["offer"] : var.linux_distribution_list[lower(var.linux_distribution_name)]["offer"]
      sku       = var.custom_image != null ? var.custom_image["sku"] : var.linux_distribution_list[lower(var.linux_distribution_name)]["sku"]
      version   = var.custom_image != null ? var.custom_image["version"] : var.linux_distribution_list[lower(var.linux_distribution_name)]["version"]
    }
  }

  os_disk {
    storage_account_type = var.os_disk_storage_account_type
    caching              = "ReadWrite"
  }
}

#---------------------------------------
# Windows Virtual machine
#---------------------------------------
resource "azurerm_windows_virtual_machine" "win_vm" {
  count                      = var.os_flavor == "windows" ? 1 : 0
  name                       = var.virtual_machine_name
  computer_name              = var.virtual_machine_name
  resource_group_name        = data.azurerm_resource_group.rg.name
  location                   = data.azurerm_resource_group.rg.location
  size                       = var.virtual_machine_size
  admin_username             = var.admin_username
  admin_password             = var.admin_password == null ? random_password.passwd[0].result : var.admin_password
  network_interface_ids      = [azurerm_network_interface.nic.id]
  source_image_id            = var.source_image_id != null ? var.source_image_id : null
  provision_vm_agent         = true
  allow_extension_operations = true
  dedicated_host_id          = var.dedicated_host_id
  license_type               = var.license_type
  availability_set_id        = var.enable_vm_availability_set == true ? azurerm_availability_set.aset[0].id : null
  timezone                   = var.vm_time_zone
  tags                       = merge({ "ResourceName" = var.virtual_machine_name }, var.tags, )

  lifecycle {
    ignore_changes = [tags]
  }

  dynamic "source_image_reference" {
    for_each = var.source_image_id != null ? [] : [1]
    content {
      publisher = var.custom_image != null ? var.custom_image["publisher"] : var.windows_distribution_list[lower(var.windows_distribution_name)]["publisher"]
      offer     = var.custom_image != null ? var.custom_image["offer"] : var.windows_distribution_list[lower(var.windows_distribution_name)]["offer"]
      sku       = var.custom_image != null ? var.custom_image["sku"] : var.windows_distribution_list[lower(var.windows_distribution_name)]["sku"]
      version   = var.custom_image != null ? var.custom_image["version"] : var.windows_distribution_list[lower(var.windows_distribution_name)]["version"]
    }
  }

  os_disk {
    storage_account_type = var.os_disk_storage_account_type
    caching              = "ReadWrite"
  }
}

#--------------------------------------------------------------
# Azure Log Analytics Workspace Agent Installation for windows
#--------------------------------------------------------------
resource "azurerm_virtual_machine_extension" "omsagentwin" {
  count                      = var.log_analytics_workspace_name != null && var.os_flavor == "windows" ? 1 : 0
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
  count                      = var.log_analytics_workspace_name != null && var.os_flavor == "linux" ? 1 : 0
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
  count                = var.ad_domain_name != null && var.os_flavor == "windows" ? 1 : 0
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

  depends_on = [azurerm_windows_virtual_machine.win_vm]

  lifecycle {
    ignore_changes = [tags]
  }
}

#---------------------------------------
# Azure DSC onboarding and Baseline configuration for Windows Virtual Machine
#---------------------------------------
resource "azurerm_virtual_machine_extension" "AzureDSC" {
  count                      = var.ad_domain_name != null && var.os_flavor == "windows" ? 1 : 0
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

  depends_on = [azurerm_windows_virtual_machine.win_vm, azurerm_virtual_machine_extension.domjoin]

  lifecycle {
    ignore_changes = [tags]
  }
}

#--------------------------------------
# Network Security Group diagnostics
#--------------------------------------
resource "azurerm_monitor_diagnostic_setting" "nsg" {
  count                      = var.log_analytics_workspace_name != null && var.vm_storage_account_name != null ? 1 : 0
  name                       = lower("nsg-${var.virtual_machine_name}-diag")
  target_resource_id         = azurerm_network_security_group.nsg.id
  storage_account_id         = data.azurerm_storage_account.storeacc.0.id
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.logws.0.id

  dynamic "log" {
    for_each = var.nsg_diag_logs
    content {
      category = log.value
      enabled  = true

      retention_policy {
        enabled = false
      }
    }
  }
}