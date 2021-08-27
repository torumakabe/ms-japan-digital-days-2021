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

resource "azurerm_resource_group" "nw_latency_eval" {
  name     = local.nw_latency_eval_rg
  location = local.nw_latency_eval_location
}

resource "azurerm_virtual_network" "vnet_default" {
  name                = "vnet-default"
  resource_group_name = azurerm_resource_group.nw_latency_eval.name
  location            = azurerm_resource_group.nw_latency_eval.location
  address_space       = ["10.0.0.0/8"]
}

resource "azurerm_subnet" "vm" {
  name                 = "subnet-vm"
  resource_group_name  = azurerm_resource_group.nw_latency_eval.name
  virtual_network_name = azurerm_virtual_network.vnet_default.name
  address_prefixes     = ["10.0.0.0/16"]
}

resource "azurerm_public_ip" "nw_latency_eval" {
  for_each            = { for i, vm in local.vms : i => vm }
  name                = "pip-nw-latency-eval-${each.key}"
  location            = azurerm_resource_group.nw_latency_eval.location
  resource_group_name = azurerm_resource_group.nw_latency_eval.name
  sku                 = "Standard"
  allocation_method   = "Static"
  availability_zone   = each.value.zone
}

resource "azurerm_network_interface" "nw_latency_eval" {
  for_each                      = { for i, vm in local.vms : i => vm }
  name                          = "nic-nw-latency-eval-${each.key}"
  location                      = azurerm_resource_group.nw_latency_eval.location
  resource_group_name           = azurerm_resource_group.nw_latency_eval.name
  enable_accelerated_networking = each.value.enable_accelerated_networking


  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vm.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.nw_latency_eval[each.key].id
  }
}

resource "azurerm_network_security_group" "ssh" {
  # Workaround https://github.com/hashicorp/terraform/issues/24663
  depends_on = [
    azurerm_network_interface.nw_latency_eval,
  ]
  name                = "nsg-ssh"
  location            = azurerm_resource_group.nw_latency_eval.location
  resource_group_name = azurerm_resource_group.nw_latency_eval.name

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

resource "azurerm_proximity_placement_group" "nw_latency_eval" {
  name                = "ppg-nw-latency-eval"
  location            = azurerm_resource_group.nw_latency_eval.location
  resource_group_name = azurerm_resource_group.nw_latency_eval.name
}

resource "azurerm_network_interface_security_group_association" "nic_ssh" {
  for_each = { for i, vm in local.vms : i => vm }
  # Workaround https://github.com/hashicorp/terraform/issues/24663
  depends_on = [
    azurerm_network_interface.nw_latency_eval,
    azurerm_network_security_group.ssh
  ]
  network_interface_id      = azurerm_network_interface.nw_latency_eval[each.key].id
  network_security_group_id = azurerm_network_security_group.ssh.id
}

resource "azurerm_linux_virtual_machine" "nw_latency_eval" {
  for_each = { for i, vm in local.vms : i => vm }
  # Workaround https://github.com/hashicorp/terraform/issues/24663
  depends_on = [
    azurerm_network_interface.nw_latency_eval,
    azurerm_network_interface_security_group_association.nic_ssh
  ]
  name                            = "vm-nw-latency-eval-${each.key}"
  resource_group_name             = azurerm_resource_group.nw_latency_eval.name
  location                        = azurerm_resource_group.nw_latency_eval.location
  zone                            = each.value.zone
  size                            = each.value.size
  admin_username                  = local.vm_admin_user
  disable_password_authentication = true
  network_interface_ids = [
    azurerm_network_interface.nw_latency_eval[each.key].id,
  ]
  proximity_placement_group_id = each.value.enable_proximity_placement_group ? azurerm_proximity_placement_group.nw_latency_eval.id : null

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
}
