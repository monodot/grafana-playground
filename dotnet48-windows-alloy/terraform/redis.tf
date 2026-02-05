resource "azurerm_redis_cache" "main" {
  name                 = "${var.prefix}-redis"
  location             = azurerm_resource_group.main.location
  resource_group_name  = azurerm_resource_group.main.name
  capacity             = 0
  family               = "C"
  sku_name             = "Basic"  # NOTE: unsuitable for production environments, no SLA
  non_ssl_port_enabled = false
  minimum_tls_version  = "1.2"

  redis_configuration {
  }
}

resource "azurerm_redis_firewall_rule" "vnet" {
  name                = "allow_from_vnet"
  redis_cache_name    = azurerm_redis_cache.main.name
  resource_group_name = azurerm_resource_group.main.name
  start_ip            = "10.0.2.0"
  end_ip              = "10.0.2.255"
}

resource "azurerm_redis_firewall_rule" "vm_public_ips" {
  count               = var.vm_count
  name                = "allow_vm_${count.index}"
  redis_cache_name    = azurerm_redis_cache.main.name
  resource_group_name = azurerm_resource_group.main.name
  start_ip            = azurerm_public_ip.vm[count.index].ip_address
  end_ip              = azurerm_public_ip.vm[count.index].ip_address
}