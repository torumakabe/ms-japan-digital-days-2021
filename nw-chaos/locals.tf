locals {
  nw_chaos_rg       = "rg-nw-chaos"
  nw_chaos_location = "japaneast"
  vm_admin_user     = "adminuser"
  vms = [
    {
      zone = "1"
      size = "Standard_D2d_v4"
    },
    {
      zone = "2"
      size = "Standard_D2d_v4"
    },
  ]
  nsg_rule_injection = null
  /*
  nsg_rule_injection = {
    name                       = "ethr"
    priority                   = 200
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8888"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  */
}
