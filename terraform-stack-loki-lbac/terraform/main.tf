terraform {
  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = "2.11.0"
    }
  }
}

provider "grafana" {
  alias         = "cloud"
  cloud_api_key = var.grafana_cloud_api_key
}

// See: https://registry.terraform.io/providers/grafana/grafana/latest/docs

resource "grafana_cloud_stack" "demo" {
  provider    = grafana.cloud
  name        = "Tom D Loki LBAC Demo"
  slug        = "lokilbacdemo"
  region_slug = "us"
}

resource "grafana_cloud_stack_service_account" "cloud_sa" {
  provider   = grafana.cloud
  stack_slug = grafana_cloud_stack.demo.slug

  name        = "cloud service account"
  role        = "Admin"
  is_disabled = false
}

resource "grafana_cloud_stack_service_account_token" "cloud_sa" {
  provider   = grafana.cloud
  stack_slug = grafana_cloud_stack.demo.slug

  name               = "lokilbacdemo cloud_sa key"
  service_account_id = grafana_cloud_stack_service_account.cloud_sa.id
}

data "grafana_data_source" "loki_default" {
  provider = grafana.stack
  uid      = "grafanacloud-logs"
}

# Restrict the default Loki data source to only Admins
resource "grafana_data_source_permission" "loki_default" {
  provider      = grafana.stack
  datasource_id = data.grafana_data_source.loki_default.id # "grafanacloud-lokilbacdemo-logs"
  permissions {
    built_in_role = "Admin"
    permission    = "Admin"
  }
}


provider "grafana" {
  alias = "stack"
  url   = grafana_cloud_stack.demo.url
  auth  = grafana_cloud_stack_service_account_token.cloud_sa.key
}

data "grafana_cloud_organization" "current" {
  provider = grafana.cloud
  slug     = "tomdonohue" // Obviously replace this with your own organisation :) 
}
