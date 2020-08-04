locals {
  nsg_inbound_rules = { for idx, security_rule in var.nsg_inbound_rules : security_rule.name => {
    idx : idx,
    security_rule : security_rule,
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

#----------------------------------------------------------
# Resource Group, VNet, Subnet selection & Random Resources
#----------------------------------------------------------
data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

data "azurerm_virtual_network" "vnet" {
  name                = var.virtual_network_name
  resource_group_name = data.azurerm_resource_group.rg.name
}

data "azurerm_subnet" "snet" {
  name                 = var.subnet_name
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  resource_group_name  = data.azurerm_resource_group.rg.name
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
  count   = var.enable_public_ip_address == true ? var.instances_count : 0
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
  count               = var.enable_public_ip_address == true ? var.instances_count : 0
  name                = lower("pip-vm-${var.virtual_machine_name}-${data.azurerm_resource_group.rg.location}-0${count.index + 1}")
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = format("%s%s", lower(replace(var.virtual_machine_name, "/[[:^alnum:]]/", "")), random_string.str[count.index].result)
  tags                = merge({ "ResourceName" = lower("pip-vm-${var.virtual_machine_name}-${data.azurerm_resource_group.rg.location}-0${count.index + 1}") }, var.tags, )
}

#---------------------------------------
# Network Interface for Virtual Machine
#---------------------------------------
resource "azurerm_network_interface" "nic" {
  count                         = var.instances_count
  name                          = lower("nic-${format("vm%s%s", lower(replace(var.virtual_machine_name, "/[[:^alnum:]]/", "")), count.index + 1)}")
  resource_group_name           = data.azurerm_resource_group.rg.name
  location                      = data.azurerm_resource_group.rg.location
  dns_servers                   = var.dns_servers
  enable_ip_forwarding          = var.enable_ip_forwarding
  enable_accelerated_networking = var.enable_accelerated_networking
  tags                          = merge({ "ResourceName" = lower("nic-${format("vm%s%s", lower(replace(var.virtual_machine_name, "/[[:^alnum:]]/", "")), count.index + 1)}") }, var.tags, )

  ip_configuration {
    name                          = lower("ipconig-${format("vm%s%s", lower(replace(var.virtual_machine_name, "/[[:^alnum:]]/", "")), count.index + 1)}")
    primary                       = true
    subnet_id                     = data.azurerm_subnet.snet.id
    private_ip_address_allocation = var.private_ip_address_allocation_type
    private_ip_address            = var.private_ip_address_allocation_type == "Static" ? element(concat(var.private_ip_address, [""]), count.index) : null
    public_ip_address_id          = var.enable_public_ip_address == true ? element(concat(azurerm_public_ip.pip.*.id, [""]), count.index) : null
  }
}

resource "azurerm_availability_set" "aset" {
  count                        = var.enable_vm_availability_set ? 1 : 0
  name                         = lower("avail-${var.virtual_machine_name}-${data.azurerm_resource_group.rg.location}")
  resource_group_name          = data.azurerm_resource_group.rg.name
  location                     = data.azurerm_resource_group.rg.location
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true
  tags                         = merge({ "ResourceName" = lower("avail-${var.virtual_machine_name}-${data.azurerm_resource_group.rg.location}") }, var.tags, )
}

#---------------------------------------------------------------
# Network security group for Virtual Machine Network Interface
#---------------------------------------------------------------
resource "azurerm_network_security_group" "nsg" {
  name                = lower("nsg_${var.virtual_machine_name}_${data.azurerm_resource_group.rg.location}_in")
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  tags                = merge({ "ResourceName" = lower("nsg_${var.virtual_machine_name}_${data.azurerm_resource_group.rg.location}_in") }, var.tags, )
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
  count                     = var.instances_count
  network_interface_id      = element(concat(azurerm_network_interface.nic.*.id, [""]), count.index)
  network_security_group_id = azurerm_network_security_group.nsg.id
}

#---------------------------------------
# Linux Virutal machine
#---------------------------------------
resource "azurerm_linux_virtual_machine" "linux_vm" {
  count                      = var.os_flavor == "linux" ? var.instances_count : 0
  name                       = format("%s%s", lower(replace(var.virtual_machine_name, "/[[:^alnum:]]/", "")), count.index + 1)
  resource_group_name        = data.azurerm_resource_group.rg.name
  location                   = data.azurerm_resource_group.rg.location
  size                       = var.virtual_machine_size
  admin_username             = var.admin_username
  admin_password             = var.disable_password_authentication != true && var.admin_password == null ? element(concat(random_password.passwd.*.result, [""]), 0) : var.admin_password
  network_interface_ids      = [element(concat(azurerm_network_interface.nic.*.id, [""]), count.index)]
  source_image_id            = var.source_image_id != null ? var.source_image_id : null
  provision_vm_agent         = true
  allow_extension_operations = true
  dedicated_host_id          = var.dedicated_host_id
  availability_set_id        = var.enable_vm_availability_set == true ? element(concat(azurerm_availability_set.aset.*.id, [""]), 0) : null
  tags                       = merge({ "ResourceName" = format("vm-linux-%s%s", lower(replace(var.virtual_machine_name, "/[[:^alnum:]]/", "")), count.index + 1) }, var.tags, )

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.generate_admin_ssh_key == true && var.os_flavor == "linux" ? tls_private_key.rsa[0].public_key_openssh : file(var.admin_ssh_key_data)
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
# Windows Virutal machine
#---------------------------------------
resource "azurerm_windows_virtual_machine" "win_vm" {
  count                      = var.os_flavor == "windows" ? var.instances_count : 0
  name                       = format("%s%s", lower(replace(var.virtual_machine_name, "/[[:^alnum:]]/", "")), count.index + 1)
  computer_name              = format("%s%s", lower(replace(var.virtual_machine_name, "/[[:^alnum:]]/", "")), count.index + 1)
  resource_group_name        = data.azurerm_resource_group.rg.name
  location                   = data.azurerm_resource_group.rg.location
  size                       = var.virtual_machine_size
  admin_username             = var.admin_username
  admin_password             = var.admin_password == null ? element(concat(random_password.passwd.*.result, [""]), 0) : var.admin_password
  network_interface_ids      = [element(concat(azurerm_network_interface.nic.*.id, [""]), count.index)]
  source_image_id            = var.source_image_id != null ? var.source_image_id : null
  provision_vm_agent         = true
  allow_extension_operations = true
  dedicated_host_id          = var.dedicated_host_id
  license_type               = var.license_type
  availability_set_id        = var.enable_vm_availability_set == true ? element(concat(azurerm_availability_set.aset.*.id, [""]), 0) : null
  tags                       = merge({ "ResourceName" = format("%s%s", lower(replace(var.virtual_machine_name, "/[[:^alnum:]]/", "")), count.index + 1) }, var.tags, )

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

