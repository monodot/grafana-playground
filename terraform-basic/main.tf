terraform {
    required_providers {
        grafana = {
            source = "grafana/grafana"
            version = "1.36.1"
        }
    }
}

provider "grafana" {
    alias = "cloud"
    cloud_api_key = "${var.grafana_cloud_api_key}"
}

resource "grafana_cloud_stack" "stack_1" {
    provider = grafana.cloud
    name = "Test Stack 1"
    slug = "td77teststack1"
    region_slug = "prod-us-east-0"
}

resource "grafana_cloud_stack" "stack_2" {
    provider = grafana.cloud
    name = "Test Stack 2"
    slug = "td77teststack2"
    region_slug = "prod-us-east-0"
}

