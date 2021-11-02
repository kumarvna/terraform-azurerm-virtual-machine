# Azure Virtual Machines Terraform Module

Terraform module to deploy azure Windows or Linux virtual machines with Public IP, proximity placement group, Availability Set, boot diagnostics, data disks, and Network Security Group support. It supports existing ssh keys or generates ssh key pairs if required for Linux VM's. It creates random passwords as well if you are not providing the custom password for Windows VM's.

This module supports to use existing NSG group. To enable this feature, specify the argument `existing_network_security_group_id` with a valid resource id of the current NSG group and remove all NSG inbound rules from the module.

## Module Usage for

* [Linux Virtual Machine](linux_virtual_machine/)
* [Linux Virtual Machine using Existing NSG](linux_virtual_machine_using_existing_NSG/)
* [MS-SQL Windows Virtual Machine](mssql_windows_virtual_machine/)
* [Windows Virtual Machine](windows_virtual_machine/)

## Terraform Usage

To run this example you need to execute following Terraform commands

```terraform
terraform init
terraform plan
terraform apply
```

Run `terraform destroy` when you don't need these resources.

## Outputs

|Name | Description|
|---- | -----------|
`admin_ssh_key_public`|The generated public key data in PEM format
`admin_ssh_key_private`|The generated private key data in PEM format
`windows_vm_password`|Password for the Windows Virtual Machine
`linux_vm_password`|Password for the Linux Virtual Machine
`windows_vm_public_ips`|Public IP's map for the all windows Virtual Machines
`linux_vm_public_ips`|Public IP's map for the all windows Virtual Machines
`windows_vm_private_ips`|Public IP's map for the all windows Virtual Machines
`linux_vm_private_ips`|Public IP's map for the all windows Virtual Machines
`linux_virtual_machine_ids`|The resource id's of all Linux Virtual Machine
`windows_virtual_machine_ids`|The resource id's of all Windows Virtual Machine
`network_security_group_ids`|List of Network security groups and ids
`vm_availability_set_id`|The resource ID of Virtual Machine availability set
