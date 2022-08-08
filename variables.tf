variable "resource_group_name" {
  description = "A container that holds related resources for an Azure solution"
}

variable "location" {
  description = "The location/region to keep all your network resources. To get the list of all locations with table format from azure cli, run 'az account list-locations -o table'"
}

variable "virtual_network_name" {
  description = "The name of the virtual network"
  default     = ""
}

variable "virtual_network_resource_group_name" {
  description = "The name of the virtual network resource group "
  default     = ""
}

variable "subnet_name" {
  description = "The name of the subnet to use in VM scale set"
  default     = ""
}

variable "log_analytics_workspace_name" {
  description = "The name of log analytics workspace name"
  default     = null
}

variable "log_analytics_workspace_rg" {
  description = "The name of the log analytics workspace resource group"
  default     = null
}

variable "virtual_machine_name" {
  description = "The name of the virtual machine."
}

variable "os_flavor" {
  description = "Specify the flavor of the operating system image to deploy Virtual Machine. Valid values are `windows` and `linux`"
  default     = "windows"
}

variable "virtual_machine_size" {
  description = "The Virtual Machine SKU for the Virtual Machine, Default is Standard_A2_V2"
  default     = "Standard_B2s"
}

variable "patch_mode" {
  description = "Specifies the mode of in-guest patching to this Windows Virtual Machine. Possible values are AutomaticByPlatform and ImageDefault for Linux VMs and Manual, AutomaticByOS and AutomaticByPlatform for Windows VMs"
  default     = null
}

variable "enable_ip_forwarding" {
  description = "Should IP Forwarding be enabled? Defaults to false"
  default     = false
}

variable "enable_accelerated_networking" {
  description = "Should Accelerated Networking be enabled? Defaults to false."
  default     = false
}

variable "private_ip_address_allocation_type" {
  description = "The allocation method used for the Private IP Address. Possible values are Dynamic and Static."
  default     = "Dynamic"
}

variable "private_ip_address" {
  description = "The Static IP Address which should be used. This is valid only when `private_ip_address_allocation` is set to `Static` "
  default     = null
}

variable "dns_servers" {
  description = "List of dns servers to use for network interface"
  default     = []
}

variable "availability_set_id" {
  description = "Availability Set ID of availability set to add the Virtual Machine to."
  default     = null
}

variable "availability_zone" {
  description = "Index of availability zone in which the Virtual Machine should be deployed to."
  default     = null
}

variable "enable_public_ip_address" {
  description = "Reference to a Public IP Address to associate with the NIC"
  default     = null
}

variable "source_image_id" {
  description = "The ID of an Image which each Virtual Machine should be based on"
  default     = null
}

variable "backup_enabled" {
  description = ""
  type        = bool
}

variable "backup_settings" {
  description = "Provide the recovery vault and backup policy details for VM backup"
  type        = map(string)
  default     = {}
}

variable "custom_image" {
  description = "Provide the custom image to this module if the default variants are not sufficient"
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  default = null
}

variable "custom_data" {
  description = "Base64 encoded file of a bash script that gets run once by cloud-init upon VM creation"
  default     = null
}

variable "linux_distribution_list" {
  description = "Pre-defined Azure Linux VM images list"
  type = map(object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  }))

  default = {
    ubuntu1604 = {
      publisher = "Canonical"
      offer     = "UbuntuServer"
      sku       = "16.04-LTS"
      version   = "latest"
    },

    ubuntu1804 = {
      publisher = "Canonical"
      offer     = "UbuntuServer"
      sku       = "18.04-LTS"
      version   = "latest"
    },

    ubuntu2004 = {
      publisher = "Canonical"
      offer     = "0001-com-ubuntu-server-focal"
      sku       = "20_04-lts-gen2"
      version   = "latest"
    },

    ubuntu2004_1 = {
      publisher = "Canonical"
      offer     = "0001-com-ubuntu-server-focal"
      sku       = "20_04-lts"
      version   = "latest"
    },

    centos75 = {
      publisher = "OpenLogic"
      offer     = "CentOS"
      sku       = "7.5"
      version   = "latest"
    },

    centos77 = {
      publisher = "OpenLogic"
      offer     = "CentOS"
      sku       = "7.7"
      version   = "latest"
    },

    centos81 = {
      publisher = "OpenLogic"
      offer     = "CentOS"
      sku       = "8_1"
      version   = "latest"
    },

    coreos = {
      publisher = "CoreOS"
      offer     = "CoreOS"
      sku       = "Stable"
      version   = "latest"
    },

    mssql2019ent-rhel8 = {
      publisher = "MicrosoftSQLServer"
      offer     = "sql2019-rhel8"
      sku       = "enterprise"
      version   = "latest"
    },

    mssql2019std-rhel8 = {
      publisher = "MicrosoftSQLServer"
      offer     = "sql2019-rhel8"
      sku       = "standard"
      version   = "latest"
    },

    mssql2019dev-rhel8 = {
      publisher = "MicrosoftSQLServer"
      offer     = "sql2019-rhel8"
      sku       = "sqldev"
      version   = "latest"
    },

    mssql2019ent-ubuntu1804 = {
      publisher = "MicrosoftSQLServer"
      offer     = "sql2019-ubuntu1804"
      sku       = "enterprise"
      version   = "latest"
    },

    mssql2019std-ubuntu1804 = {
      publisher = "MicrosoftSQLServer"
      offer     = "sql2019-ubuntu1804"
      sku       = "standard"
      version   = "latest"
    },

    mssql2019dev-ubuntu1804 = {
      publisher = "MicrosoftSQLServer"
      offer     = "sql2019-ubuntu1804"
      sku       = "sqldev"
      version   = "latest"
    },
  }
}

variable "linux_distribution_name" {
  default     = "ubuntu1804"
  description = "Variable to pick an OS flavour for Linux based VM. Possible values include: centos8, ubuntu1804"
}

variable "windows_distribution_list" {
  description = "Pre-defined Azure Windows VM images list"
  type = map(object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  }))

  default = {
    windows2022dc = {
      publisher = "MicrosoftWindowsServer"
      offer     = "WindowsServer"
      sku       = "2022-datacenter"
      version   = "latest"
    },

    windows2022dccore = {
      publisher = "MicrosoftWindowsServer"
      offer     = "WindowsServer"
      sku       = "2022-datacenter-core"
      version   = "latest"
    },

    windows2022dcazure = {
      publisher = "MicrosoftWindowsServer"
      offer     = "WindowsServer"
      sku       = "2022-datacenter-azure-edition"
      version   = "latest"
    },

    windows2022dccoreazure = {
      publisher = "MicrosoftWindowsServer"
      offer     = "WindowsServer"
      sku       = "2022-datacenter-azure-edition-core"
      version   = "latest"
    }

    windows2019dc = {
      publisher = "MicrosoftWindowsServer"
      offer     = "WindowsServer"
      sku       = "2019-Datacenter"
      version   = "latest"
    },

    windows2019dcgen2 = {
      publisher = "MicrosoftWindowsServer"
      offer     = "WindowsServer"
      sku       = "2019-Datacenter-gensecond"
      version   = "latest"
    },

    windows2019dccore = {
      publisher = "MicrosoftWindowsServer"
      offer     = "WindowsServer"
      sku       = "2019-Datacenter-Core"
      version   = "latest"
    },

    mssql2017exp = {
      publisher = "MicrosoftSQLServer"
      offer     = "SQL2017-WS2019"
      sku       = "express"
      version   = "latest"
    },

    mssql2017dev = {
      publisher = "MicrosoftSQLServer"
      offer     = "SQL2017-WS2019"
      sku       = "sqldev"
      version   = "latest"
    },

    mssql2017std = {
      publisher = "MicrosoftSQLServer"
      offer     = "SQL2017-WS2019"
      sku       = "standard"
      version   = "latest"
    },

    mssql2017ent = {
      publisher = "MicrosoftSQLServer"
      offer     = "SQL2017-WS2019"
      sku       = "enterprise"
      version   = "latest"
    },

    mssql2019std = {
      publisher = "MicrosoftSQLServer"
      offer     = "sql2019-ws2019"
      sku       = "standard"
      version   = "latest"
    },

    mssql2019dev = {
      publisher = "MicrosoftSQLServer"
      offer     = "sql2019-ws2019"
      sku       = "sqldev"
      version   = "latest"
    },

    mssql2019ent = {
      publisher = "MicrosoftSQLServer"
      offer     = "sql2019-ws2019"
      sku       = "enterprise"
      version   = "latest"
    },

    mssql2019ent-byol = {
      publisher = "MicrosoftSQLServer"
      offer     = "sql2019-ws2019-byol"
      sku       = "enterprise"
      version   = "latest"
    },

    mssql2019std-byol = {
      publisher = "MicrosoftSQLServer"
      offer     = "sql2019-ws2019-byol"
      sku       = "standard"
      version   = "latest"
    }
  }
}

variable "windows_distribution_name" {
  default     = "windows2019dcgen2"
  description = "Variable to pick an OS flavour for Windows based VM."
}

variable "os_disk_storage_account_type" {
  description = "The Type of Storage Account which should back this the Internal OS Disk. Possible values include Standard_LRS, StandardSSD_LRS and Premium_LRS."
  default     = "StandardSSD_LRS"
}

variable "custom_osdisk_name" {
  description = "Legacy OS Diskname pre-module-version 5"
  default     = ""
}

variable "data_disks" {
  description = "Provide the data disk parameters"
  default     = []
}

variable "custom_datadisk_name" {
  description = "Legacy Data disk name pre-module-version 5"
  default     = ""
}

variable "generate_admin_ssh_key" {
  description = "Generates a secure private key and encodes it as PEM."
  default     = false
}

variable "admin_ssh_key" {
  description = "SSH key to authenticate Linux virtual machine"
  default     = null
}

variable "disable_password_authentication" {
  description = "Should Password Authentication be disabled on this Virtual Machine? Defaults to true."
  default     = true
}

variable "identity_type" {
  description = "Virtual machine identity type. Can be SystemAssigned or UserAssigned"
  default     = ""
}

variable "identity_ids" {
  description = "identity ids for virtual machine user assigned identities"
  default     = []
}

variable "ad_domain_name" {
  description = "The domain name the VM is joined to"
  default     = null
}

variable "admin_username" {
  description = "The username of the local administrator used for the Virtual Machine."
  default     = "azureadmin"
}

variable "ad_user_name" {
  description = "The username of the AD account that can join computers to the domain"
  default     = null
}

variable "admin_password" {
  description = "The Password which should be used for the local-administrator on this Virtual Machine"
  default     = null
}

variable "ad_user_password" {
  description = "The password of the AD account that can join computers to the domain"
  default     = null
}

variable "oupath" {
  description = "The username of the AD account that can join computers to the domain"
  default     = null
}

variable "nsg_inbound_rules" {
  description = "List of network rules to apply to network interface."
  default     = []
}

variable "dedicated_host_id" {
  description = "The ID of a Dedicated Host where this machine should be run on."
  default     = null
}

variable "license_type" {
  description = "Specifies the type of on-premise license which should be used for this Virtual Machine. Possible values are None, Windows_Client and Windows_Server."
  default     = "None"
}

variable "nsg_diag_logs" {
  description = "NSG Monitoring Category details for Azure Diagnostic setting"
  default     = ["NetworkSecurityGroupEvent", "NetworkSecurityGroupRuleCounter"]
}

variable "vm_time_zone" {
  description = "Specifies the Time Zone which should be used by the Virtual Machine"
  default     = "W. Europe Standard Time"
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "dsc_modulesurl" {
  description = "Url to Zip file containing configuration script"
  default     = null
}

variable "dsc_sastoken" {
  description = "SAS Token if ModulesUrl points to private Azure Blob Storage"
  default     = null
}

variable "dsc_endpoint" {
  description = "URL of automation account desc endpoint"
  default     = null
}

variable "dsc_mode" {
  description = "DSC configuration mode of the DSC node (virtual machine)"
  default     = "applyAndMonitor"
}

variable "dsc_config" {
  description = "DSC node configuration assigned to the DSC node (virtual machine)"
  default     = null
}

variable "dsc_key" {
  description = "Primary access key of the automation account DSC endpoint"
  default     = null
}