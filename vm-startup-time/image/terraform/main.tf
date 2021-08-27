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

resource "azurerm_resource_group" "vm_startup_time_eval_image" {
  name     = local.vm_startup_time_eval_image_rg
  location = local.vm_startup_time_eval_image_location
}

resource "azurerm_shared_image_gallery" "vm_startup_time_eval_image" {
  name                = "sig.vmstartuptimeeval"
  resource_group_name = azurerm_resource_group.vm_startup_time_eval_image.name
  location            = azurerm_resource_group.vm_startup_time_eval_image.location
  description         = "Shared image for evaluation of VM startup time."
}

resource "azurerm_shared_image" "vm_startup_time_eval_image_ubuntu_vanilla" {
  name                = "ubuntu-vanilla"
  gallery_name        = azurerm_shared_image_gallery.vm_startup_time_eval_image.name
  resource_group_name = azurerm_resource_group.vm_startup_time_eval_image.name
  location            = azurerm_resource_group.vm_startup_time_eval_image.location
  os_type             = "Linux"

  identifier {
    publisher = local.publisher_name
    offer     = "ubuntu-vanilla"
    sku       = "18.04-LTS"
  }
}
