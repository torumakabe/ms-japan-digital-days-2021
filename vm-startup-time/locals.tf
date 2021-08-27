locals {
  vm_startup_time_eval_rg       = "rg-vm-startup-time-eval"
  vm_startup_time_eval_location = "japaneast"
  vm_admin_user                 = "adminuser"
  platform_source_image_reference = {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  custom_source_image_resource = {
    version             = "1.0.0"
    image_name          = "ubuntu-vanilla"
    gallery_name        = "sig.vmstartuptimeeval"
    resource_group_name = "rg-vm-startup-time-eval-image"
  }
  vms = [
    {
      size = "Standard_D2ds_v4"
      os_disk = {
        storage_account_type      = "Premium_LRS"
        diff_disk_settings_option = null
        size_gb                   = 30
      }
      source_image_reference        = local.platform_source_image_reference
      enable_accelerated_networking = true
    },
    {
      size = "Standard_DS2_v2"
      os_disk = {
        storage_account_type      = "Premium_LRS"
        diff_disk_settings_option = null
        size_gb                   = 30
      }
      source_image_reference        = local.platform_source_image_reference
      enable_accelerated_networking = true
    },
    {
      size = "Standard_D2ds_v4"
      os_disk = {
        storage_account_type      = "Premium_LRS"
        diff_disk_settings_option = null
        size_gb                   = 30
      }
      source_image_reference        = local.platform_source_image_reference
      enable_accelerated_networking = false
    },
    {
      size = "Standard_D2ds_v4"
      os_disk = {
        storage_account_type      = "Standard_LRS"
        diff_disk_settings_option = "Local"
        size_gb                   = 30
      }
      source_image_reference        = local.platform_source_image_reference
      enable_accelerated_networking = true
    },
    {
      size = "Standard_D2ds_v4"
      os_disk = {
        storage_account_type      = "Standard_LRS"
        diff_disk_settings_option = null
        size_gb                   = 30
      }
      source_image_reference        = local.platform_source_image_reference
      enable_accelerated_networking = true
    },
    {
      size = "Standard_D2ds_v4"
      os_disk = {
        storage_account_type      = "Premium_LRS"
        diff_disk_settings_option = null
        size_gb                   = 30
      }
      source_image_reference        = null
      enable_accelerated_networking = true
    },
    {
      size = "Standard_D8ds_v4"
      os_disk = {
        storage_account_type      = "Premium_LRS"
        diff_disk_settings_option = null
        size_gb                   = 30
      }
      source_image_reference        = local.platform_source_image_reference
      enable_accelerated_networking = true
    },
    {
      size = "Standard_D8ds_v4"
      os_disk = {
        storage_account_type      = "Premium_LRS"
        diff_disk_settings_option = null
        size_gb                   = 100
      }
      source_image_reference        = local.platform_source_image_reference
      enable_accelerated_networking = true
    },
  ]
}
