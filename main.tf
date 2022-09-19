# Set VAULT_TOKEN environment variable
provider "vault" {
  address="${var.vault_addr}"
  auth_login {
    path = "auth/approle/login"
    parameters = {
      role_id   = "${var.role_id}"
      secret_id = "${var.secret_id}"
    }
  }
}

# vmware credentials from Vault
data "vault_generic_secret" "vmware" {
  path = "secret/config/virtualisation_technical_user"
}

# domain admin credentials
data "vault_generic_secret" "domain_admin" {
  path = "secret/config/technical_domain_admin"
}

# Set terraform backend on etcdv3 - /!\ etcd is DEPRECATED and will be removed in a future release of Terraform
terraform {
  backend "etcdv3" {
    endpoints = ["https://terraform01:2379", "https://terraform02:2379", "https://terraform03:2379"]
    lock      = true
    prefix    = "vcenter/Infrastructure/Terraform/"
  }
}

# The Provider block sets up the vSphere provider - How to connect to vCenter. Note the use of
# variables from Vault to avoid hardcoding credentials here
provider "vsphere" {
  user       = "${data.vault_generic_secret.vmware.data["username"]}"
  password       = "${data.vault_generic_secret.vmware.data["password"]}"
  vsphere_server = "${var.vsphere_server}"
  allow_unverified_ssl = true
}

# The Data sections are about determining where the virtual machine will be placed. 
# Here we are naming the vSphere DC, the cluster, datastore, virtual network and the template
# name. These are called upon later when provisioning the VM resource
data "vsphere_datacenter" "dc" {
  name = "${var.vsphere_dc}"
}
data "vsphere_datastore" "datastore" {
  name          = "${var.vsphere_datastore}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}
data "vsphere_datastore_cluster" "datastore_cluster" {
  name          = "${var.vsphere_datastore_cluster}"
  datacenter_id = "${data.vsphere_datacenter_cluster.dc.id}"
}
data "vsphere_compute_cluster" "cluster" {
    name          = "${var.vsphere_cluster}"
    datacenter_id = "${data.vsphere_datacenter.dc.id}"
}
# data "vsphere_resource_pool" "pool" {
  # name          = "${var.vsphere_pool}"
  # datacenter_id = "${data.vsphere_datacenter.dc.id}"
# }

data "vsphere_network" "network_front" {
  name          = "${var.vsphere_network_front}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_virtual_machine" "template_linux" {
  name          = "${var.vsphere_template_linux}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_virtual_machine" "template_windows" {
  name          = "${var.vsphere_template_windows}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}


# Here we define our resources aka our VMs
resource "vsphere_virtual_machine" "vm_linux" {
    name             = "terraform-test1"
    folder           = "Infrastructure"
    resource_pool_id = "${data.vsphere_compute_cluster.cluster.resource_pool_id}"
    ## Use datastore_id or datastore_cluster_id
    datastore_id     = "${data.vsphere_datastore.datastore.id}"
    #datastore_cluster_id     = "${data.vsphere_datastore_cluster.datastore_cluster.id}"
    firmware         = "${data.vsphere_virtual_machine.template.firmware}"
    num_cpus = 2
    memory   = 4096
    guest_id = "${data.vsphere_virtual_machine.template.guest_id}"
    network_interface {
        network_id   = "${data.vsphere_network.network.id}"
        adapter_type = "${data.vsphere_virtual_machine.template.network_interface_types[0]}"
    }
    disk {
        label            = "coreos"
        size             = "${data.vsphere_virtual_machine.template.disks.0.size}"
        eagerly_scrub    = "${data.vsphere_virtual_machine.template.disks.0.eagerly_scrub}"
        thin_provisioned = "${data.vsphere_virtual_machine.template.disks.0.thin_provisioned}"
    }
    scsi_type = "${data.vsphere_virtual_machine.template.scsi_type}"
    
    clone {
      template_uuid = "${data.vsphere_virtual_machine.template_linux.id}"

      customize {
        linux_options {
          host_name = "terraform-test1"
          domain    = "test.internal"
        }

        network_interface {
          ipv4_address = "10.10.10.100"
          ipv4_netmask = 24
        }

        ipv4_gateway = "10.10.10.1"
        dns_server_list = ["10.0.0.1", "10.0.0.2"]
        dns_suffix_list = ["domain"]
      }
    }
    
}


resource "vsphere_virtual_machine" "vm_windows" {
    name             = "terraform-test2"
    folder           = "Infrastructure"
    resource_pool_id = "${data.vsphere_compute_cluster.cluster.resource_pool_id}"
    ## Use datastore_id or datastore_cluster_id
    datastore_id     = "${data.vsphere_datastore.datastore.id}"
    #datastore_cluster_id     = "${data.vsphere_datastore_cluster.datastore_cluster.id}"
    firmware         = "${data.vsphere_virtual_machine.template.firmware}"
    num_cpus = 2
    memory   = 4096
    guest_id = "${data.vsphere_virtual_machine.template.guest_id}"
    network_interface {
        network_id   = "${data.vsphere_network.network.id}"
        adapter_type = "${data.vsphere_virtual_machine.template.network_interface_types[0]}"
    }
    disk {
        label            = "coreos"
        size             = "${data.vsphere_virtual_machine.template.disks.0.size}"
        eagerly_scrub    = "${data.vsphere_virtual_machine.template.disks.0.eagerly_scrub}"
        thin_provisioned = "${data.vsphere_virtual_machine.template.disks.0.thin_provisioned}"
    }
    scsi_type = "${data.vsphere_virtual_machine.template.scsi_type}"
    
    clone {
      template_uuid = "${data.vsphere_virtual_machine.template_windows.id}"

      customize {
        windows_options {
          computer_name = "terraform-test2"
          join_domain    = "domain"
          domain_admin_user = "${data.vault_generic_secret.domain_admin.data["username"]}"
          domain_admin_password = "${data.vault_generic_secret.domain_admin.data["password"]}"
        }

        network_interface {
          ipv4_address = "10.10.10.101"
          ipv4_netmask = 24
        }

        ipv4_gateway = "10.10.10.1"
        dns_server_list = ["10.0.0.1", "10.0.0.2"]
        dns_suffix_list = ["domain"]
      }
    }
    
}
