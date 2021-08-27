terraform {
  required_version = "~> 1.0.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.73"
    }
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_shared_image_version" "ubuntu_vanilla" {
  name                = local.custom_source_image_resource.version
  image_name          = local.custom_source_image_resource.image_name
  gallery_name        = local.custom_source_image_resource.gallery_name
  resource_group_name = local.custom_source_image_resource.resource_group_name
}

resource "azurerm_resource_group" "vm_startup_time_eval" {
  name     = local.vm_startup_time_eval_rg
  location = local.vm_startup_time_eval_location
}

resource "azurerm_virtual_network" "vnet_default" {
  name                = "vnet-default"
  resource_group_name = azurerm_resource_group.vm_startup_time_eval.name
  location            = azurerm_resource_group.vm_startup_time_eval.location
  address_space       = ["10.0.0.0/8"]
}

resource "azurerm_subnet" "vm" {
  name                 = "subnet-vm"
  resource_group_name  = azurerm_resource_group.vm_startup_time_eval.name
  virtual_network_name = azurerm_virtual_network.vnet_default.name
  address_prefixes     = ["10.0.0.0/16"]
}

resource "azurerm_public_ip" "vm_startup_time_eval" {
  for_each            = { for i, vm in local.vms : i => vm }
  name                = "pip-vm-startup-time-eval-${each.key}"
  location            = azurerm_resource_group.vm_startup_time_eval.location
  resource_group_name = azurerm_resource_group.vm_startup_time_eval.name
  sku                 = "Standard"
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "vm_startup_time_eval" {
  for_each                      = { for i, vm in local.vms : i => vm }
  name                          = "nic-vm-startup-time-eval-${each.key}"
  location                      = azurerm_resource_group.vm_startup_time_eval.location
  resource_group_name           = azurerm_resource_group.vm_startup_time_eval.name
  enable_accelerated_networking = each.value.enable_accelerated_networking

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vm.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm_startup_time_eval[each.key].id
  }
}

resource "azurerm_network_security_group" "ssh" {
  # Workaround https://github.com/hashicorp/terraform/issues/24663
  depends_on = [
    azurerm_network_interface.vm_startup_time_eval,
  ]
  name                = "nsg-ssh"
  location            = azurerm_resource_group.vm_startup_time_eval.location
  resource_group_name = azurerm_resource_group.vm_startup_time_eval.name

  security_rule {
    name                       = "ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "nic_ssh" {
  for_each = { for i, vm in local.vms : i => vm }
  # Workaround https://github.com/hashicorp/terraform/issues/24663
  depends_on = [
    azurerm_network_interface.vm_startup_time_eval,
    azurerm_network_security_group.ssh
  ]
  network_interface_id      = azurerm_network_interface.vm_startup_time_eval[each.key].id
  network_security_group_id = azurerm_network_security_group.ssh.id
}

resource "azurerm_linux_virtual_machine" "vm_startup_time_eval" {
  for_each = { for i, vm in local.vms : i => vm }
  # Workaround https://github.com/hashicorp/terraform/issues/24663
  depends_on = [
    azurerm_network_interface.vm_startup_time_eval,
    azurerm_network_interface_security_group_association.nic_ssh
  ]
  name                            = "vm-vm-startup-time-eval-${each.key}"
  resource_group_name             = azurerm_resource_group.vm_startup_time_eval.name
  location                        = azurerm_resource_group.vm_startup_time_eval.location
  size                            = each.value.size
  admin_username                  = local.vm_admin_user
  disable_password_authentication = true
  network_interface_ids = [
    azurerm_network_interface.vm_startup_time_eval[each.key].id,
  ]

  admin_ssh_key {
    username   = local.vm_admin_user
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadOnly"
    storage_account_type = each.value.os_disk.storage_account_type
    dynamic "diff_disk_settings" {
      for_each = each.value.os_disk.diff_disk_settings_option != null ? ["set"] : []
      content {
        option = each.value.os_disk.diff_disk_settings_option
      }
    }
    disk_size_gb = each.value.os_disk.size_gb
  }

  dynamic "source_image_reference" {
    for_each = each.value.source_image_reference != null ? ["set"] : []
    content {
      publisher = each.value.source_image_reference.publisher
      offer     = each.value.source_image_reference.offer
      sku       = each.value.source_image_reference.sku
      version   = each.value.source_image_reference.version
    }
  }

  source_image_id = each.value.source_image_reference != null ? null : data.azurerm_shared_image_version.ubuntu_vanilla.id

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = local.vm_admin_user
      host        = azurerm_public_ip.vm_startup_time_eval[each.key].ip_address
      private_key = file("~/.ssh/id_rsa")
    }

    inline = [
      "echo hello",
    ]
  }
}
