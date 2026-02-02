output "load_balancer_ip" {
  value = azurerm_public_ip.lb.ip_address
}

output "application_url" {
  value       = "http://${azurerm_public_ip.lb.ip_address}"
  description = "URL to access the demo application through the load balancer"
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

output "redis_hostname" {
  value       = azurerm_redis_cache.main.hostname
  description = "Redis cache hostname"
}

output "redis_ssl_port" {
  value       = azurerm_redis_cache.main.ssl_port
  description = "Redis SSL port (default: 6380)"
}

output "redis_primary_key" {
  value       = azurerm_redis_cache.main.primary_access_key
  sensitive   = true
  description = "Redis primary access key (sensitive)"
}
