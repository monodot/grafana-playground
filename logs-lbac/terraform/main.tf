terraform {
  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = ">= 1.39, < 2.0.0"
      #version = "~> 1.38.0"
    }
  }
}

provider "grafana" {
  alias         = "cloud"
  cloud_api_key = var.grafana_cloud_api_key
}

data "grafana_cloud_organization" "current" {
  provider = grafana.cloud
  slug     = var.grafana_cloud_org_slug
}

# Define an access policy to allow a user access to a limited subset of logs
resource "grafana_cloud_access_policy" "developer" {
  provider     = grafana.cloud
  region       = var.grafana_cloud_region # this should correspond to the region of the Cloud Stack
  name         = "developer-policy"
  display_name = "Developer Policy"

  scopes = ["metrics:read", "logs:read"]

  realm {
    type       = "org"
    identifier = data.grafana_cloud_organization.current.id

    label_policy {
      selector = "{environment=\"development\"}"
    }

    label_policy {
      selector = "{classification=\"internal\"}"
    }
  }
}

resource "grafana_cloud_access_policy_token" "developer" {
  provider         = grafana.cloud
  region           = var.grafana_cloud_region
  access_policy_id = grafana_cloud_access_policy.developer.policy_id
  name             = "developer-policy-token"
  display_name     = "Developer Policy Token"
  expires_at       = "2030-01-01T00:00:00Z"
}
