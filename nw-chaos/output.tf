output "public_ips" {
  value = {
    for i, vm in local.vms : i => azurerm_public_ip.nw_chaos[i].ip_address
  }
}

output "private_ips" {
  value = {
    for i, vm in local.vms : i => azurerm_network_interface.nw_chaos[i].private_ip_address
  }
}
