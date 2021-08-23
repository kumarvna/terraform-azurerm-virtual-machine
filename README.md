# Azure Virtual Machines Terraform Module

This terraform module is designed to deploy azure Windows or Linux virtual machines with Public IP, Availability Set and Network Security Group support.

These types of resources supported:

* [Linux Virtual Machine](https://www.terraform.io/docs/providers/azurerm/r/linux_virtual_machine.html)
* [Windows Virtual Machine](https://www.terraform.io/docs/providers/azurerm/r/windows_virtual_machine.html)
* [Linux VM with SQL Server](https://docs.microsoft.com/en-us/azure/azure-sql/virtual-machines/linux/sql-vm-create-portal-quickstart)
* [Windows VM with SQL Server](https://docs.microsoft.com/en-us/azure/azure-sql/virtual-machines/windows/sql-vm-create-portal-quickstart)
* [Public IP](https://www.terraform.io/docs/providers/azurerm/r/public_ip.html)
* [Network Security Group](https://www.terraform.io/docs/providers/azurerm/r/network_security_group.html)
* [Availability Set](https://www.terraform.io/docs/providers/azurerm/r/availability_set.html)
* [SSH2 Key generation for Dev Environments](https://www.terraform.io/docs/providers/tls/r/private_key.html)
* [Azure Monitoring Diagnostics](https://www.terraform.io/docs/providers/azurerm/r/monitor_diagnostic_setting.html)

## Module Usage

```hcl
module "virtual-machine" {
  source  = "kumarvna/virtual-machine/azurerm"
  version = "2.0.0"

  # Resource Group, location, VNet and Subnet details
  resource_group_name  = "rg-hub-demo-internal-shared-westeurope-001"
  location             = "westeurope"
  virtual_network_name = "vnet-default-hub-westeurope"
  subnet_name          = "snet-management-default-hub-westeurope"
  virtual_machine_name = "vm-linux"

  # (Optional) To enable Azure Monitoring and install log analytics agents
  log_analytics_workspace_name = var.log_analytics_workspace_id
  hub_storage_account_name     = var.hub_storage_account_id

  # This module support multiple Pre-Defined Linux and Windows Distributions.
  # Linux images: ubuntu2004, ubuntu1804, ubuntu1604, centos75, centos77, centos81, coreos
  # Windows Images: windows2019dc, windows2019dcgen2, windows2012r2dc, windows2016dc, windows2019dc, windows2016dccore
  # MSSQL 2017 images: mssql2017exp, mssql2017dev, mssql2017std, mssql2017ent
  # MSSQL 2019 images: mssql2019dev, mssql2019std, mssql2019ent
  # MSSQL 2019 Linux OS Images:
  # RHEL8 images: mssql2019ent-rhel8, mssql2019std-rhel8, mssql2019dev-rhel8
  # Ubuntu images: mssql2019ent-ubuntu1804, mssql2019std-ubuntu1804, mssql2019dev-ubuntu1804
  # Bring your own License (BOYL) images: mssql2019ent-byol, mssql2019std-byol
  os_flavor                  = "linux"
  linux_distribution_name    = "ubuntu1804"
  virtual_machine_size       = "Standard_A2_v2"
  generate_admin_ssh_key     = false
  admin_ssh_key_data         = "~/.ssh/id_rsa.pub"
  enable_vm_availability_set = true

  # Network Seurity group port allow definitions for each Virtual Machine
  # NSG association to be added automatically for all network interfaces.
  # SSH port 22 and 3389 is exposed to the Internet recommended for only testing.
  # For production environments, recommended to use a VPN or private connection.
  nsg_inbound_rules = [
    {
      name                   = "ssh"
      destination_port_range = "22"
      source_address_prefix  = "*"
    },

    {
      name                   = "http"
      destination_port_range = "80"
      source_address_prefix  = "*"
    },
  ]

  # Adding TAG's to your Azure resources (Required)
  # ProjectName and Env are already declared above, to use them here, create a varible.
  tags = {
    ProjectName  = "demo-internal"
    Env          = "dev"
    Owner        = "user@example.com"
    BusinessUnit = "CORP"
    ServiceClass = "Gold"
  }
}
```

## Default Local Administrator and the Password

This module utilizes __`azureadmin`__ as a local administrator on virtual machines. If you want to you use custom username, then specify the same by setting up the argument `admin_username` with valid user string.

By default, this module generates a strong password for all virtual machines. If you want to set the custom password, specify the argument `admin_password` with valid string.

This module also generates SSH2 Key pair for Linux servers by default, however, it is only recommended to use for dev environment. For production environments, please generate your own SSH2 key with a passphrase and input the key by providing the path to the argument `admin_ssh_key_data`.

## Pre-Defined Windows and Linux VM Images

There are pre-defined Windows or Linux images available to deploy by setting up the argument `linux_distribution_name` or `windows_distribution_name` with this module.

OS type |Available Pre-defined Images|
--------|----------------------------|
Linux |`ubuntu2004`, `ubuntu1804`, `ubuntu1604`, `centos75`, `centos77`, `centos81`, `coreos`
Windows|`windows2019dc`, `windows2019dcgen2`, `windows2012r2dc`, `windows2016dc`, `windows2019dc`, `windows2016dccore`
MS SQL 2017|`mssql2017exp`, `mssql2017dev`, `mssql2017std`, `mssql2017ent`
MS SQL 2019|`mssql2019dev`, `mssql2019std`, `mssql2019ent`
MS SQL 2019 Linux (RHEL8)|`mssql2019ent-rhel8`, `mssql2019std-rhel8`, `mssql2019dev-rhel8`
MS SQL 2019 Linux (Ubuntu)|`mssql2019ent-ubuntu1804`, `mssql2019std-ubuntu1804`, `mssql2019dev-ubuntu1804`
MS SQL 2019 Bring your own License (BOYL)|`mssql2019ent-byol`, `mssql2019std-byol`

## Custom Virtual Machine images

If the pre-defined Windows or Linux variants are not sufficient then, you can specify the custom image by setting up the argument `custom_image` with appropriate values. Custom images can be used to bootstrap configurations such as preloading applications, application configurations, and other OS configurations. For more information [check here](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/tutorial-custom-images)

```hcl
module "virtual-machine" {
  source  = "kumarvna/virtual-machine/azurerm"
  version = "2.0.0"

  # .... omitted

  os_flavor                  = "linux"
  enable_vm_availability_set = true
  enable_public_ip_address   = true

  custom_image = {
      publisher = "myPublisher"
      offer     = "myOffer"
      sku       = "mySKU"
      version   = "latest"
    }

  # .... omitted
```

## Custom DNS servers

This is an optional feature and only applicable if you are using your own DNS servers superseding default DNS services provided by Azure. Set the argument `dns_servers = ["4.4.4.4"]` to enable this option. For multiple DNS servers, set the argument `dns_servers = ["4.4.4.4", "8.8.8.8"]`

## Advanced Usage of the Module

### `disable_password_authentication` - enable or disable VM password authentication

While creating the Linux servers, its recommended to use ssh2 keys to log in than using a password. By default, this module generates the ssh2 key pair for Linux VM's. If you want the password to login Linux VM, set the argument `disable_password_authentication = false`, this instructs the module to create a random password.

### `enable_ip_forwarding` - enable or disable IP forwarding

The setting must be enabled for every network interface that is attached to the virtual machine that receives traffic that the virtual machine needs to forward. A virtual machine can forward traffic whether it has multiple network interfaces or a single network interface attached to it. While IP forwarding is an Azure setting, the virtual machine must also run an application able to forward the traffic, such as firewall, WAN optimization, and load balancing applications. IP forwarding is typically used with user-defined routes.

By default, this not enabled and set to disable. To enable the IP forwarding using this module, set the argument `enable_ip_forwarding = true`.

### `enable_accelerated_networking` for Virtual Machines

Accelerated networking enables single root I/O virtualization (SR-IOV) to a VM, greatly improving its networking performance. This high-performance path bypasses the host from the data path, which reduces latency, jitter, and CPU utilization for the most demanding network workloads on supported VM types.

Accelerated Networking is supported on most general-purpose and compute-optimized instance sizes with two or more virtual CPUs (vCPUs). These supported series are Dv2/DSv2 and F/Fs.

On instances that support hyperthreading, accelerated networking is supported on VM instances with four or more vCPUs. Supported series are: D/Dsv3, D/Dsv4, E/Esv3, Ea/Easv4, Fsv2, Lsv2, Ms/Mms, and Ms/Mmsv2.

By default, this not enabled and set to disable. To enable the accelerated networking using this module, set the argument `enable_accelerated_networking = true`.

### `private_ip_address_allocation_type` - Static IP Assignment

By default, the Azure DHCP servers assign the private IPv4 address for the primary IP configuration of the Azure network interface to the network interface within the virtual machine operating system. Unless necessary, you should never manually set the IP address of a network interface within the virtual machine's operating system.

By default this not enabled and set to disable. To enable the static private IP using this module, set the argument `private_ip_address_allocation_type = "Static"` and set the argument `private_ip_address` with valid static private IP.

### `dedicated_host_id` - Adding Azure Dedicated Hosts

Azure Dedicated Host is a service that provides physical servers - able to host one or more virtual machines - dedicated to one Azure subscription. Dedicated hosts are the same physical servers used in our data centers, provided as a resource. You can provision dedicated hosts within a region, availability zone, and fault domain. Virtual machine scale sets are not currently supported on dedicated hosts.

By default, this not enabled and set to disable. To add a dedicated host to Virtual machine using this module, set the argument `dedicated_host_id` with valid dedicated host resource ID. It is possible to add Dedicated Host resource outside this module.  

### `enable_vm_availability_set` - Create highly available virtual machines

An Availability Set is a logical grouping capability for isolating VM resources from each other when they're deployed. Azure makes sure that the VMs you place within an Availability Set run across multiple physical servers, compute racks, storage units, and network switches. If a hardware or software failure happens, only a subset of your VMs are impacted and your overall solution stays operational. Availability Sets are essential for building reliable cloud solutions.

By default, this not enabled and set to disable. To enable the Availability Set using this module, set the argument `enable_vm_availability_set = true`.

### `source_image_id` - Create a VM from a managed image

We can create multiple virtual machines from an Azure managed VM image. A managed VM image contains the information necessary to create a VM, including the OS and data disks. The virtual hard disks (VHDs) that make up the image, including both the OS disks and any data disks, are stored as managed disks. One managed image supports up to 20 simultaneous deployments.

When you use the managed VM image, custom image, or any other source image reference are not valid. By default, this not enabled and set to use predefined or custom images. To utilize Azure managed VM Image by this module, set the argument `source_image_id` with valid manage image resource id.

### `license_type` - Bring your own License to your Windows server

Azure Hybrid Benefit for Windows Server allows you to use your on-premises Windows Server licenses and run Windows virtual machines on Azure at a reduced cost. You can use Azure Hybrid Benefit for Windows Server to deploy new virtual machines with Windows OS.

By default, this is set to `None`. To use the Azure Hybrid Benefit for windows server deployment by this module, set the argument `license_type` to valid values. Possible values are `None`, `Windows_Client` and `Windows_Server`.

### `os_disk_storage_account_type` - Azure managed disks

Azure managed disks are block-level storage volumes that are managed by Azure and used with Azure Virtual Machines. Managed disks are like a physical disk in an on-premises server but virtualized. With managed disks, all you have to do is specify the disk size, the disk type, and provision the disk. Once you provision the disk, Azure handles the rest. The available types of disks are ultra disks, premium solid-state drives (SSD), standard SSDs, and standard hard disk drives (HDD).

By default, this module uses the standard SSD with Locally redundant storage (`StandardSSD_LRS`). To use other type of disks, set the argument `os_disk_storage_account_type` with valid values. Possible values are `Standard_LRS`, `StandardSSD_LRS` and `Premium_LRS`.

## Network Security Groups

By default, the network security groups connected to Network Interface and allow necessary traffic and block everything else (deny-all rule). Use `nsg_inbound_rules` in this Terraform module to create a Network Security Group (NSG) for network interface and allow it to add additional rules for inbound flows.

In the Source and Destination columns, `VirtualNetwork`, `AzureLoadBalancer`, and `Internet` are service tags, rather than IP addresses. In the protocol column, Any encompasses `TCP`, `UDP`, and `ICMP`. When creating a rule, you can specify `TCP`, `UDP`, `ICMP` or `*`. `0.0.0.0/0` in the Source and Destination columns represents all addresses.

*You cannot remove the default rules, but you can override them by creating rules with higher priorities.*

```hcl
module "virtual-machine" {
  source  = "kumarvna/virtual-machine/azurerm"
  version = "2.0.0"

  # .... omitted
  
  os_flavor                  = "linux"
  linux_distribution_name    = "ubuntu1804"
  virtual_machine_size       = "Standard_A2_v2"  
  generate_admin_ssh_key     = false
  admin_ssh_key_data         = "./id_rsa.pub"

  nsg_inbound_rules = [
    {
      name                   = "ssh"
      destination_port_range = "22"
      source_address_prefix  = "*"
    },

    {
      name                   = "http"
      destination_port_range = "80"
      source_address_prefix  = "*"
    },
  ]
}
```

## Recommended naming and tagging conventions

Well-defined naming and metadata tagging conventions help to quickly locate and manage resources. These conventions also help associate cloud usage costs with business teams via chargeback and show back accounting mechanisms.

### Resource naming

An effective naming convention assembles resource names by using important resource information as parts of a resource's name. For example, using these [recommended naming conventions](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/naming-and-tagging#example-names), a public IP resource for a production SharePoint workload is named like this: `pip-sharepoint-prod-westus-001`.

> ### Metadata tags

When applying metadata tags to the cloud resources, you can include information about those assets that couldn't be included in the resource name. You can use that information to perform more sophisticated filtering and reporting on resources. This information can be used by IT or business teams to find resources or generate reports about resource usage and billing.

The following list provides the recommended common tags that capture important context and information about resources. Use this list as a starting point to establish your tagging conventions.

Tag Name|Description|Key|Example Value|Required?
--------|-----------|---|-------------|---------|
Project Name|Name of the Project for the infra is created. This is mandatory to create a resource names.|ProjectName|{Project name}|Yes
Application Name|Name of the application, service, or workload the resource is associated with.|ApplicationName|{app name}|Yes
Approver|Name Person responsible for approving costs related to this resource.|Approver|{email}|Yes
Business Unit|Top-level division of your company that owns the subscription or workload the resource belongs to. In smaller organizations, this may represent a single corporate or shared top-level organizational element.|BusinessUnit|FINANCE, MARKETING,{Product Name},CORP,SHARED|Yes
Cost Center|Accounting cost center associated with this resource.|CostCenter|{number}|Yes
Disaster Recovery|Business criticality of this application, workload, or service.|DR|Mission Critical, Critical, Essential|Yes
Environment|Deployment environment of this application, workload, or service.|Env|Prod, Dev, QA, Stage, Test|Yes
Owner Name|Owner of the application, workload, or service.|Owner|{email}|Yes
Requester Name|User that requested the creation of this application.|Requestor| {email}|Yes
Service Class|Service Level Agreement level of this application, workload, or service.|ServiceClass|Dev, Bronze, Silver, Gold|Yes
Start Date of the project|Date when this application, workload, or service was first deployed.|StartDate|{date}|No
End Date of the Project|Date when this application, workload, or service is planned to be retired.|EndDate|{date}|No

> This module allows you to manage the above metadata tags directly or as an variable using `variables.tf`. All Azure resources which support tagging can be tagged by specifying key-values in argument `tags`. Tag `ResourceName` is added automatically to all resources.

```hcl
module "virtual-machine" {
  source  = "kumarvna/virtual-machine/azurerm"
  version = "2.0.0"

  # Resource Group, location, VNet and Subnet details
  resource_group_name  = "rg-hub-demo-internal-shared-westeurope-001"

  # ... omitted

  tags = {
    ProjectName  = "demo-internal"
    Env          = "dev"
    Owner        = "user@example.com"
    BusinessUnit = "CORP"
    ServiceClass = "Gold"
  }
}
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 2.59 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | ~> 2.59 |
| <a name="provider_azurerm.shared"></a> [azurerm.shared](#provider\_azurerm.shared) | ~> 2.59 |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |
| <a name="provider_tls"></a> [tls](#provider\_tls) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_availability_set.aset](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/availability_set) | resource |
| [azurerm_backup_protected_vm.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/backup_protected_vm) | resource |
| [azurerm_linux_virtual_machine.linux_vm](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine) | resource |
| [azurerm_managed_disk.data_disk](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/managed_disk) | resource |
| [azurerm_monitor_diagnostic_setting.nsg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [azurerm_network_interface.nic](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) | resource |
| [azurerm_network_interface_security_group_association.nsgassoc](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface_security_group_association) | resource |
| [azurerm_network_security_group.nsg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) | resource |
| [azurerm_network_security_rule.nsg_rule](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule) | resource |
| [azurerm_public_ip.pip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_virtual_machine_data_disk_attachment.data_disk](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_data_disk_attachment) | resource |
| [azurerm_virtual_machine_extension.AzureDSC](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_extension) | resource |
| [azurerm_virtual_machine_extension.domjoin](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_extension) | resource |
| [azurerm_virtual_machine_extension.omsagentlinux](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_extension) | resource |
| [azurerm_virtual_machine_extension.omsagentwin](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_extension) | resource |
| [azurerm_windows_virtual_machine.win_vm](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/windows_virtual_machine) | resource |
| [random_password.passwd](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_string.str](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [tls_private_key.rsa](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [azurerm_backup_policy_vm.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/backup_policy_vm) | data source |
| [azurerm_log_analytics_workspace.logws](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/log_analytics_workspace) | data source |
| [azurerm_subnet.snet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subnet) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ad_domain_name"></a> [ad\_domain\_name](#input\_ad\_domain\_name) | The domain name the VM is joined to | `any` | `null` | no |
| <a name="input_ad_user_name"></a> [ad\_user\_name](#input\_ad\_user\_name) | The username of the AD account that can join computers to the domain | `any` | `null` | no |
| <a name="input_ad_user_password"></a> [ad\_user\_password](#input\_ad\_user\_password) | The password of the AD account that can join computers to the domain | `any` | `null` | no |
| <a name="input_admin_password"></a> [admin\_password](#input\_admin\_password) | The Password which should be used for the local-administrator on this Virtual Machine | `any` | `null` | no |
| <a name="input_admin_ssh_key"></a> [admin\_ssh\_key](#input\_admin\_ssh\_key) | SSH key to authenticate Linux virtual machine | `any` | `null` | no |
| <a name="input_admin_username"></a> [admin\_username](#input\_admin\_username) | The username of the local administrator used for the Virtual Machine. | `string` | `"azureadmin"` | no |
| <a name="input_backup_enabled"></a> [backup\_enabled](#input\_backup\_enabled) | n/a | `bool` | n/a | yes |
| <a name="input_backup_settings"></a> [backup\_settings](#input\_backup\_settings) | Provide the recovery vault and backup policy details for VM backup | `map(string)` | `{}` | no |
| <a name="input_custom_data"></a> [custom\_data](#input\_custom\_data) | Base64 encoded file of a bash script that gets run once by cloud-init upon VM creation | `any` | `null` | no |
| <a name="input_custom_image"></a> [custom\_image](#input\_custom\_image) | Provide the custom image to this module if the default variants are not sufficient | <pre>map(object({<br>    publisher = string<br>    offer     = string<br>    sku       = string<br>    version   = string<br>  }))</pre> | `null` | no |
| <a name="input_data_disks"></a> [data\_disks](#input\_data\_disks) | Provide the data disk parameters | `list` | `[]` | no |
| <a name="input_dedicated_host_id"></a> [dedicated\_host\_id](#input\_dedicated\_host\_id) | The ID of a Dedicated Host where this machine should be run on. | `any` | `null` | no |
| <a name="input_disable_password_authentication"></a> [disable\_password\_authentication](#input\_disable\_password\_authentication) | Should Password Authentication be disabled on this Virtual Machine? Defaults to true. | `bool` | `true` | no |
| <a name="input_dns_servers"></a> [dns\_servers](#input\_dns\_servers) | List of dns servers to use for network interface | `list` | `[]` | no |
| <a name="input_dsc_config"></a> [dsc\_config](#input\_dsc\_config) | DSC node configuration assigned to the DSC node (virtual machine) | `any` | `null` | no |
| <a name="input_dsc_endpoint"></a> [dsc\_endpoint](#input\_dsc\_endpoint) | URL of automation account desc endpoint | `any` | `null` | no |
| <a name="input_dsc_key"></a> [dsc\_key](#input\_dsc\_key) | Primary access key of the automation account DSC endpoint | `any` | `null` | no |
| <a name="input_dsc_mode"></a> [dsc\_mode](#input\_dsc\_mode) | DSC configuration mode of the DSC node (virtual machine) | `string` | `"applyAndMonitor"` | no |
| <a name="input_dsc_modulesurl"></a> [dsc\_modulesurl](#input\_dsc\_modulesurl) | Url to Zip file containing configuration script | `any` | `null` | no |
| <a name="input_dsc_sastoken"></a> [dsc\_sastoken](#input\_dsc\_sastoken) | SAS Token if ModulesUrl points to private Azure Blob Storage | `any` | `null` | no |
| <a name="input_enable_accelerated_networking"></a> [enable\_accelerated\_networking](#input\_enable\_accelerated\_networking) | Should Accelerated Networking be enabled? Defaults to false. | `bool` | `false` | no |
| <a name="input_enable_ip_forwarding"></a> [enable\_ip\_forwarding](#input\_enable\_ip\_forwarding) | Should IP Forwarding be enabled? Defaults to false | `bool` | `false` | no |
| <a name="input_enable_public_ip_address"></a> [enable\_public\_ip\_address](#input\_enable\_public\_ip\_address) | Reference to a Public IP Address to associate with the NIC | `any` | `null` | no |
| <a name="input_enable_vm_availability_set"></a> [enable\_vm\_availability\_set](#input\_enable\_vm\_availability\_set) | Manages an Availability Set for Virtual Machines. | `bool` | `false` | no |
| <a name="input_generate_admin_ssh_key"></a> [generate\_admin\_ssh\_key](#input\_generate\_admin\_ssh\_key) | Generates a secure private key and encodes it as PEM. | `bool` | `false` | no |
| <a name="input_license_type"></a> [license\_type](#input\_license\_type) | Specifies the type of on-premise license which should be used for this Virtual Machine. Possible values are None, Windows\_Client and Windows\_Server. | `string` | `"None"` | no |
| <a name="input_linux_distribution_list"></a> [linux\_distribution\_list](#input\_linux\_distribution\_list) | Pre-defined Azure Linux VM images list | <pre>map(object({<br>    publisher = string<br>    offer     = string<br>    sku       = string<br>    version   = string<br>  }))</pre> | <pre>{<br>  "centos75": {<br>    "offer": "CentOS",<br>    "publisher": "OpenLogic",<br>    "sku": "7.5",<br>    "version": "latest"<br>  },<br>  "centos77": {<br>    "offer": "CentOS",<br>    "publisher": "OpenLogic",<br>    "sku": "7.7",<br>    "version": "latest"<br>  },<br>  "centos81": {<br>    "offer": "CentOS",<br>    "publisher": "OpenLogic",<br>    "sku": "8_1",<br>    "version": "latest"<br>  },<br>  "coreos": {<br>    "offer": "CoreOS",<br>    "publisher": "CoreOS",<br>    "sku": "Stable",<br>    "version": "latest"<br>  },<br>  "mssql2019dev-rhel8": {<br>    "offer": "sql2019-rhel8",<br>    "publisher": "MicrosoftSQLServer",<br>    "sku": "sqldev",<br>    "version": "latest"<br>  },<br>  "mssql2019dev-ubuntu1804": {<br>    "offer": "sql2019-ubuntu1804",<br>    "publisher": "MicrosoftSQLServer",<br>    "sku": "sqldev",<br>    "version": "latest"<br>  },<br>  "mssql2019ent-rhel8": {<br>    "offer": "sql2019-rhel8",<br>    "publisher": "MicrosoftSQLServer",<br>    "sku": "enterprise",<br>    "version": "latest"<br>  },<br>  "mssql2019ent-ubuntu1804": {<br>    "offer": "sql2019-ubuntu1804",<br>    "publisher": "MicrosoftSQLServer",<br>    "sku": "enterprise",<br>    "version": "latest"<br>  },<br>  "mssql2019std-rhel8": {<br>    "offer": "sql2019-rhel8",<br>    "publisher": "MicrosoftSQLServer",<br>    "sku": "standard",<br>    "version": "latest"<br>  },<br>  "mssql2019std-ubuntu1804": {<br>    "offer": "sql2019-ubuntu1804",<br>    "publisher": "MicrosoftSQLServer",<br>    "sku": "standard",<br>    "version": "latest"<br>  },<br>  "ubuntu1604": {<br>    "offer": "UbuntuServer",<br>    "publisher": "Canonical",<br>    "sku": "16.04-LTS",<br>    "version": "latest"<br>  },<br>  "ubuntu1804": {<br>    "offer": "UbuntuServer",<br>    "publisher": "Canonical",<br>    "sku": "18.04-LTS",<br>    "version": "latest"<br>  },<br>  "ubuntu2004": {<br>    "offer": "UbuntuServer",<br>    "publisher": "Canonical",<br>    "sku": "20.04-LTS",<br>    "version": "latest"<br>  }<br>}</pre> | no |
| <a name="input_linux_distribution_name"></a> [linux\_distribution\_name](#input\_linux\_distribution\_name) | Variable to pick an OS flavour for Linux based VM. Possible values include: centos8, ubuntu1804 | `string` | `"ubuntu1804"` | no |
| <a name="input_location"></a> [location](#input\_location) | The location/region to keep all your network resources. To get the list of all locations with table format from azure cli, run 'az account list-locations -o table' | `any` | n/a | yes |
| <a name="input_log_analytics_workspace_name"></a> [log\_analytics\_workspace\_name](#input\_log\_analytics\_workspace\_name) | The name of log analytics workspace name | `any` | `null` | no |
| <a name="input_log_analytics_workspace_rg"></a> [log\_analytics\_workspace\_rg](#input\_log\_analytics\_workspace\_rg) | The name of the log analytics workspace resource group | `any` | `null` | no |
| <a name="input_nsg_diag_logs"></a> [nsg\_diag\_logs](#input\_nsg\_diag\_logs) | NSG Monitoring Category details for Azure Diagnostic setting | `list` | <pre>[<br>  "NetworkSecurityGroupEvent",<br>  "NetworkSecurityGroupRuleCounter"<br>]</pre> | no |
| <a name="input_nsg_inbound_rules"></a> [nsg\_inbound\_rules](#input\_nsg\_inbound\_rules) | List of network rules to apply to network interface. | `list` | `[]` | no |
| <a name="input_os_disk_storage_account_type"></a> [os\_disk\_storage\_account\_type](#input\_os\_disk\_storage\_account\_type) | The Type of Storage Account which should back this the Internal OS Disk. Possible values include Standard\_LRS, StandardSSD\_LRS and Premium\_LRS. | `string` | `"StandardSSD_LRS"` | no |
| <a name="input_os_flavor"></a> [os\_flavor](#input\_os\_flavor) | Specify the flavor of the operating system image to deploy Virtual Machine. Valid values are `windows` and `linux` | `string` | `"windows"` | no |
| <a name="input_oupath"></a> [oupath](#input\_oupath) | The username of the AD account that can join computers to the domain | `any` | `null` | no |
| <a name="input_private_ip_address"></a> [private\_ip\_address](#input\_private\_ip\_address) | The Static IP Address which should be used. This is valid only when `private_ip_address_allocation` is set to `Static` | `any` | `null` | no |
| <a name="input_private_ip_address_allocation_type"></a> [private\_ip\_address\_allocation\_type](#input\_private\_ip\_address\_allocation\_type) | The allocation method used for the Private IP Address. Possible values are Dynamic and Static. | `string` | `"Dynamic"` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | A container that holds related resources for an Azure solution | `any` | n/a | yes |
| <a name="input_source_image_id"></a> [source\_image\_id](#input\_source\_image\_id) | The ID of an Image which each Virtual Machine should be based on | `any` | `null` | no |
| <a name="input_subnet_name"></a> [subnet\_name](#input\_subnet\_name) | The name of the subnet to use in VM scale set | `string` | `""` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources | `map(string)` | `{}` | no |
| <a name="input_virtual_machine_name"></a> [virtual\_machine\_name](#input\_virtual\_machine\_name) | The name of the virtual machine. | `any` | n/a | yes |
| <a name="input_virtual_machine_size"></a> [virtual\_machine\_size](#input\_virtual\_machine\_size) | The Virtual Machine SKU for the Virtual Machine, Default is Standard\_A2\_V2 | `string` | `"Standard_B2s"` | no |
| <a name="input_virtual_network_name"></a> [virtual\_network\_name](#input\_virtual\_network\_name) | The name of the virtual network | `string` | `""` | no |
| <a name="input_virtual_network_resource_group_name"></a> [virtual\_network\_resource\_group\_name](#input\_virtual\_network\_resource\_group\_name) | The name of the virtual network resource group | `string` | `""` | no |
| <a name="input_vm_storage_account_id"></a> [vm\_storage\_account\_id](#input\_vm\_storage\_account\_id) | The name of the vm storage id to store logs | `any` | `null` | no |
| <a name="input_vm_time_zone"></a> [vm\_time\_zone](#input\_vm\_time\_zone) | Specifies the Time Zone which should be used by the Virtual Machine | `string` | `"W. Europe Standard Time"` | no |
| <a name="input_windows_distribution_list"></a> [windows\_distribution\_list](#input\_windows\_distribution\_list) | Pre-defined Azure Windows VM images list | <pre>map(object({<br>    publisher = string<br>    offer     = string<br>    sku       = string<br>    version   = string<br>  }))</pre> | <pre>{<br>  "mssql2017dev": {<br>    "offer": "SQL2017-WS2019",<br>    "publisher": "MicrosoftSQLServer",<br>    "sku": "sqldev",<br>    "version": "latest"<br>  },<br>  "mssql2017ent": {<br>    "offer": "SQL2017-WS2019",<br>    "publisher": "MicrosoftSQLServer",<br>    "sku": "enterprise",<br>    "version": "latest"<br>  },<br>  "mssql2017exp": {<br>    "offer": "SQL2017-WS2019",<br>    "publisher": "MicrosoftSQLServer",<br>    "sku": "express",<br>    "version": "latest"<br>  },<br>  "mssql2017std": {<br>    "offer": "SQL2017-WS2019",<br>    "publisher": "MicrosoftSQLServer",<br>    "sku": "standard",<br>    "version": "latest"<br>  },<br>  "mssql2019dev": {<br>    "offer": "sql2019-ws2019",<br>    "publisher": "MicrosoftSQLServer",<br>    "sku": "sqldev",<br>    "version": "latest"<br>  },<br>  "mssql2019ent": {<br>    "offer": "sql2019-ws2019",<br>    "publisher": "MicrosoftSQLServer",<br>    "sku": "enterprise",<br>    "version": "latest"<br>  },<br>  "mssql2019ent-byol": {<br>    "offer": "sql2019-ws2019-byol",<br>    "publisher": "MicrosoftSQLServer",<br>    "sku": "enterprise",<br>    "version": "latest"<br>  },<br>  "mssql2019std": {<br>    "offer": "sql2019-ws2019",<br>    "publisher": "MicrosoftSQLServer",<br>    "sku": "standard",<br>    "version": "latest"<br>  },<br>  "mssql2019std-byol": {<br>    "offer": "sql2019-ws2019-byol",<br>    "publisher": "MicrosoftSQLServer",<br>    "sku": "standard",<br>    "version": "latest"<br>  },<br>  "windows2012r2dc": {<br>    "offer": "WindowsServer",<br>    "publisher": "MicrosoftWindowsServer",<br>    "sku": "2012-R2-Datacenter",<br>    "version": "latest"<br>  },<br>  "windows2016dc": {<br>    "offer": "WindowsServer",<br>    "publisher": "MicrosoftWindowsServer",<br>    "sku": "2016-Datacenter",<br>    "version": "latest"<br>  },<br>  "windows2016dccore": {<br>    "offer": "WindowsServer",<br>    "publisher": "MicrosoftWindowsServer",<br>    "sku": "2016-Datacenter-Server-Core",<br>    "version": "latest"<br>  },<br>  "windows2019dc": {<br>    "offer": "WindowsServer",<br>    "publisher": "MicrosoftWindowsServer",<br>    "sku": "2019-Datacenter",<br>    "version": "latest"<br>  },<br>  "windows2019dcgen2": {<br>    "offer": "WindowsServer",<br>    "publisher": "MicrosoftWindowsServer",<br>    "sku": "2019-Datacenter-gensecond",<br>    "version": "latest"<br>  }<br>}</pre> | no |
| <a name="input_windows_distribution_name"></a> [windows\_distribution\_name](#input\_windows\_distribution\_name) | Variable to pick an OS flavour for Windows based VM. Possible values include: winserver, wincore, winsql | `string` | `"windows2019dcgen2"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_admin_ssh_key_private"></a> [admin\_ssh\_key\_private](#output\_admin\_ssh\_key\_private) | The generated private key data in PEM format |
| <a name="output_admin_ssh_key_public"></a> [admin\_ssh\_key\_public](#output\_admin\_ssh\_key\_public) | The generated public key data in PEM format |
| <a name="output_linux_virtual_machine_ids"></a> [linux\_virtual\_machine\_ids](#output\_linux\_virtual\_machine\_ids) | The resource id's of all Linux Virtual Machine. |
| <a name="output_linux_vm_private_ips"></a> [linux\_vm\_private\_ips](#output\_linux\_vm\_private\_ips) | Public IP's map for the all windows Virtual Machines |
| <a name="output_linux_vm_public_ips"></a> [linux\_vm\_public\_ips](#output\_linux\_vm\_public\_ips) | Public IP's map for the all windows Virtual Machines |
| <a name="output_network_security_group_ids"></a> [network\_security\_group\_ids](#output\_network\_security\_group\_ids) | List of Network security groups and ids |
| <a name="output_vm_availability_set_id"></a> [vm\_availability\_set\_id](#output\_vm\_availability\_set\_id) | The resource ID of Virtual Machine availability set |
| <a name="output_windows_virtual_machine_ids"></a> [windows\_virtual\_machine\_ids](#output\_windows\_virtual\_machine\_ids) | The resource id's of all Windows Virtual Machine. |
| <a name="output_windows_vm_password"></a> [windows\_vm\_password](#output\_windows\_vm\_password) | Password for the windows VM |
| <a name="output_windows_vm_private_ips"></a> [windows\_vm\_private\_ips](#output\_windows\_vm\_private\_ips) | Public IP's map for the all windows Virtual Machines |
| <a name="output_windows_vm_public_ips"></a> [windows\_vm\_public\_ips](#output\_windows\_vm\_public\_ips) | Public IP's map for the all windows Virtual Machines |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Resource Graph

![Resource Graph](graph.png)

## Authors

Module is maintained by [Kumaraswamy Vithanala](mailto:kumarvna@gmail.com) with the help from other awesome contributors.

## Other resources

* [Windows Virtual Machine](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/)
* [Linux Virtual Machine](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/)
* [Linux VM running SQL Server](https://docs.microsoft.com/en-us/azure/azure-sql/virtual-machines/linux/sql-vm-create-portal-quickstart)
* [Windows VM running SQL Server](https://docs.microsoft.com/en-us/azure/azure-sql/virtual-machines/windows/sql-vm-create-portal-quickstart)
* [Terraform AzureRM Provider Documentation](https://www.terraform.io/docs/providers/azurerm/index.html)
