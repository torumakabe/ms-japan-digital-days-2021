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

resource "azurerm_resource_group" "nw_chaos" {
  name     = local.nw_chaos_rg
  location = local.nw_chaos_location
}

resource "azurerm_virtual_network" "vnet_default" {
  name                = "vnet-default"
  resource_group_name = azurerm_resource_group.nw_chaos.name
  location            = azurerm_resource_group.nw_chaos.location
  address_space       = ["10.0.0.0/8"]
}

resource "azurerm_subnet" "vm" {
  name                 = "subnet-vm"
  resource_group_name  = azurerm_resource_group.nw_chaos.name
  virtual_network_name = azurerm_virtual_network.vnet_default.name
  address_prefixes     = ["10.0.0.0/16"]
}

resource "azurerm_public_ip" "nw_chaos" {
  for_each            = { for i, vm in local.vms : i => vm }
  name                = "pip-nw-chaos-${each.key}"
  location            = azurerm_resource_group.nw_chaos.location
  resource_group_name = azurerm_resource_group.nw_chaos.name
  sku                 = "Standard"
  allocation_method   = "Static"
  availability_zone   = each.value.zone
}

resource "azurerm_network_interface" "nw_chaos" {
  for_each                      = { for i, vm in local.vms : i => vm }
  name                          = "nic-nw-chaos-${each.key}"
  location                      = azurerm_resource_group.nw_chaos.location
  resource_group_name           = azurerm_resource_group.nw_chaos.name
  enable_accelerated_networking = true


  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vm.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.nw_chaos[each.key].id
  }
}

resource "azurerm_network_security_group" "ssh" {
  # Workaround https://github.com/hashicorp/terraform/issues/24663
  depends_on = [
    azurerm_network_interface.nw_chaos,
  ]
  name                = "nsg-ssh"
  location            = azurerm_resource_group.nw_chaos.location
  resource_group_name = azurerm_resource_group.nw_chaos.name

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


  dynamic "security_rule" {
    for_each = local.nsg_rule_injection != null ? ["set"] : []
    content {
      name                       = local.nsg_rule_injection.name
      priority                   = local.nsg_rule_injection.priority
      direction                  = local.nsg_rule_injection.direction
      access                     = local.nsg_rule_injection.access
      protocol                   = local.nsg_rule_injection.protocol
      source_port_range          = local.nsg_rule_injection.source_port_range
      destination_port_range     = local.nsg_rule_injection.destination_port_range
      source_address_prefix      = local.nsg_rule_injection.source_address_prefix
      destination_address_prefix = local.nsg_rule_injection.destination_address_prefix
    }
  }
}

resource "azurerm_network_interface_security_group_association" "nic_ssh" {
  for_each = { for i, vm in local.vms : i => vm }
  # Workaround https://github.com/hashicorp/terraform/issues/24663
  depends_on = [
    azurerm_network_interface.nw_chaos,
    azurerm_network_security_group.ssh
  ]
  network_interface_id      = azurerm_network_interface.nw_chaos[each.key].id
  network_security_group_id = azurerm_network_security_group.ssh.id
}

resource "azurerm_linux_virtual_machine" "nw_chaos" {
  for_each = { for i, vm in local.vms : i => vm }
  # Workaround https://github.com/hashicorp/terraform/issues/24663
  depends_on = [
    azurerm_network_interface.nw_chaos,
    azurerm_network_interface_security_group_association.nic_ssh
  ]
  name                            = "vm-nw-chaos-${each.key}"
  resource_group_name             = azurerm_resource_group.nw_chaos.name
  location                        = azurerm_resource_group.nw_chaos.location
  zone                            = each.value.zone
  size                            = each.value.size
  admin_username                  = local.vm_admin_user
  disable_password_authentication = true
  network_interface_ids = [
    azurerm_network_interface.nw_chaos[each.key].id,
  ]

  admin_ssh_key {
    username   = local.vm_admin_user
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadOnly"
    storage_account_type = "Standard_LRS"
    diff_disk_settings {
      option = "Local"
    }
    disk_size_gb = 30
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  custom_data = filebase64("./init.sh")

  provisioner "file" {
    connection {
      type        = "ssh"
      user        = local.vm_admin_user
      host        = azurerm_public_ip.nw_chaos[each.key].ip_address
      private_key = file("~/.ssh/id_rsa")
    }

    source      = "scripts/"
    destination = "/home/${local.vm_admin_user}"
  }
}
