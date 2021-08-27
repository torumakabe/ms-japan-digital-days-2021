variable "subscription_id" {
  type        = string
  default     = "your-subscription-id"
}

variable "resource_group_name" {
  type        = string
  default     = "rg-vm-startup-time-eval-image"
}

source "azure-arm" "ubuntu-vanilla" {
  use_azure_cli_auth = true

  shared_image_gallery_destination {
    subscription = var.subscription_id
    resource_group = var.resource_group_name
    gallery_name = "sig.vmstartuptimeeval"
    image_name = "ubuntu-vanilla"
    image_version = "1.0.0"
    replication_regions = ["japaneast"]
    storage_account_type = "Standard_ZRS"
  }
  managed_image_name = "ubuntu-vanilla"
  managed_image_resource_group_name = var.resource_group_name

  os_type = "Linux"
  image_publisher = "Canonical"
  image_offer = "UbuntuServer"
  image_sku = "18.04-LTS"

  location = "japaneast"
  vm_size = "Standard_D2ds_v4"
}

build {
  sources = ["sources.azure-arm.ubuntu-vanilla"]
}
