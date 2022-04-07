variable "vsphere_dc" {
	description = "Enter here the datacenter name"
	default = "VMWare"
}

variable "vsphere_datastore" {
	description = "Enter here the datastore name, not needed if you use vsphere_datastore_cluster"
	default= "LUN01"
}

variable "vsphere_datastore_cluster" {
	description = "Enter here the datastore cluster name, not needed if you use vsphere_datastore"
	default= "LUN_CLUSTER"
}

variable "vsphere_cluster" {
	description = "Enter here the compute cluster name"
	default= "TESTING"
}

variable "vsphere_pool" {
	description = ""
	default= ""
}

variable "vsphere_network" {
	description = "Enter here the network attached to the VM interface"
	default= "VLAN10"
}

variable "vsphere_template" {
	description = "Enter here the template to build the VM with"
	default= "rhel8.4"
}

variable "vsphere_server" {
	description = "Enter here the address of the vcenter"
	default = "vcenter.domain"
}

variable "vault_addr" {
	description = "Address of the Vault server"
	default = "https://vault.domain"
}
