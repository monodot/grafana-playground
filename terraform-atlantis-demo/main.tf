terraform {
  # This tells Atlantis to store the terraform state file in a known, fixed location.
  # This is only added for the purposes of being able to run a simple demo, locally.
  # In the real world, you would configure an s3 or remote backend here, instead!
  backend "local" {
    path = "/atlantis-data/shared-state/terraform.tfstate"
  }

  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = "~> 3.0"
    }
  }
}

provider "grafana" {
  url  = var.grafana_url
  auth = var.grafana_api_key
}

variable "grafana_url" {
  description = "Grafana Cloud instance URL (e.g., https://mystack.grafana.net)"
  type        = string
}

variable "grafana_api_key" {
  description = "Grafana Cloud service account token"
  type        = string
  sensitive   = true
}

resource "grafana_folder" "terraform_managed" {
  title = "Terraform Managed"
}

# Dashboard: Simple Demo
resource "grafana_dashboard" "demo" {
  folder      = grafana_folder.terraform_managed.id
  config_json = file("${path.module}/dashboards/demo.json")
  overwrite   = true
}

# Add more dashboards by adding more resources:
# resource "grafana_dashboard" "another" {
#   folder      = grafana_folder.terraform_managed.id
#   config_json = file("${path.module}/dashboards/another.json")
#   overwrite   = true
# }


