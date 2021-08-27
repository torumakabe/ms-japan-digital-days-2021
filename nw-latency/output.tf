output "public_ips" {
  value = {
    for i, vm in local.vms : i => azurerm_public_ip.nw_latency_eval[i].ip_address
  }
}

output "private_ips" {
  value = {
    for i, vm in local.vms : i => azurerm_network_interface.nw_latency_eval[i].private_ip_address
  }
}
