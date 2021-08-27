locals {
  nw_latency_eval_rg       = "rg-nw-latency-eval"
  nw_latency_eval_location = "japaneast"
  vm_admin_user            = "adminuser"
  vms = [
    {
      zone                             = "1"
      size                             = "Standard_D2d_v4"
      enable_accelerated_networking    = false
      enable_proximity_placement_group = false
    },
    {
      zone                             = "1"
      size                             = "Standard_D2d_v4"
      enable_accelerated_networking    = false
      enable_proximity_placement_group = false
    },
    {
      zone                             = "1"
      size                             = "Standard_D2d_v4"
      enable_accelerated_networking    = true
      enable_proximity_placement_group = true
    },
    {
      zone                             = "1"
      size                             = "Standard_D2d_v4"
      enable_accelerated_networking    = true
      enable_proximity_placement_group = false
    },
    {
      zone                             = "1"
      size                             = "Standard_D2d_v4"
      enable_accelerated_networking    = true
      enable_proximity_placement_group = true
    },
    {
      zone                             = "2"
      size                             = "Standard_D2d_v4"
      enable_accelerated_networking    = true
      enable_proximity_placement_group = false
    },
    {
      zone                             = "3"
      size                             = "Standard_D2d_v4"
      enable_accelerated_networking    = true
      enable_proximity_placement_group = false
    },
  ]
}
