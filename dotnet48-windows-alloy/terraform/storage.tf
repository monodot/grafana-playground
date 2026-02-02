# Storage Account for scripts
resource "azurerm_storage_account" "scripts" {
  name                     = "${var.prefix}scripts${random_string.storage_suffix.result}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "random_string" "storage_suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_storage_container" "scripts" {
  name                  = "scripts"
  storage_account_name  = azurerm_storage_account.scripts.name
  container_access_type = "private"
}

resource "azurerm_storage_blob" "setup_script" {
  name                   = "setup.ps1"
  storage_account_name   = azurerm_storage_account.scripts.name
  storage_container_name = azurerm_storage_container.scripts.name
  type                   = "Block"
  source_content = templatefile("${path.module}/templates/setup.ps1", {
    grafana_cloud_cloud_access_policy_token = var.grafana_cloud_cloud_access_policy_token
    grafana_cloud_hosted_metrics_id         = var.grafana_cloud_hosted_metrics_id
    grafana_cloud_hosted_metrics_url        = var.grafana_cloud_hosted_metrics_url
    grafana_cloud_hosted_logs_id            = var.grafana_cloud_hosted_logs_id
    grafana_cloud_hosted_logs_url           = var.grafana_cloud_hosted_logs_url
    grafana_cloud_fm_url                    = var.grafana_cloud_fm_url
    grafana_cloud_fm_hosted_id              = var.grafana_cloud_fm_hosted_id
    cheese_app_release_tag                  = var.cheese_app_release_tag
    redis_host                              = azurerm_redis_cache.main.hostname
    redis_port                              = "6380"
    redis_password                          = azurerm_redis_cache.main.primary_access_key
  })
}

resource "azurerm_storage_blob" "alloy_config" {
  name                   = "windows_scrape.alloy"
  storage_account_name   = azurerm_storage_account.scripts.name
  storage_container_name = azurerm_storage_container.scripts.name
  type                   = "Block"
  source                 = "${path.module}/templates/windows_scrape.alloy"
}

resource "azurerm_storage_blob" "alloy_config_app_o11y" {
  name                   = "app_o11y.alloy"
  storage_account_name   = azurerm_storage_account.scripts.name
  storage_container_name = azurerm_storage_container.scripts.name
  type                   = "Block"
  source_content = templatefile("${path.module}/templates/app_o11y.alloy", {
    grafana_cloud_otlp_user_id = var.grafana_cloud_otlp_user_id
  })
}

# Generate SAS token for script access
data "azurerm_storage_account_blob_container_sas" "scripts" {
  connection_string = azurerm_storage_account.scripts.primary_connection_string
  container_name    = azurerm_storage_container.scripts.name

  start  = timestamp()
  expiry = timeadd(timestamp(), "24h")

  permissions {
    read   = true
    add    = false
    create = false
    write  = false
    delete = false
    list   = false
  }
}
