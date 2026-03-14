terraform {
  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = "4.28.0"
    }
  }
}

provider "grafana" {
  url = "http://localhost:3001" // Talk to mitmproxy, which will proxy to grafana (otel-lgtm)
  auth    = "admin:admin"
  retries = 150 // Bump this higher than the default, which is 5
}

// An example data source. mitmproxy will inject 4 failures.
resource "grafana_data_source" "prometheus" {
  type                = "prometheus"
  name                = "mimir"
  url                 = "https://prom.example.com"
  basic_auth_enabled  = true
  basic_auth_username = "username"

  json_data_encoded = jsonencode({
    httpMethod        = "POST"
    prometheusType    = "Mimir"
    prometheusVersion = "2.4.0"
  })

  secure_json_data_encoded = jsonencode({
    basicAuthPassword = "password"
  })
}
