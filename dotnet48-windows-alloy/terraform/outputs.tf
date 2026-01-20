output "load_balancer_ip" {
  value = azurerm_public_ip.lb.ip_address
}

output "vm_names" {
  value = azurerm_windows_virtual_machine.main[*].name
}

output "vm_public_ips" {
  value = azurerm_public_ip.vm[*].ip_address
  description = "Public IP addresses for RDP access to VMs"
}

output "vm_rdp_addresses" {
  value = {
    for i in range(var.vm_count) :
    azurerm_windows_virtual_machine.main[i].name => azurerm_public_ip.vm[i].ip_address
  }
  description = "Map of VM names to their public IPs for RDP access"
}
