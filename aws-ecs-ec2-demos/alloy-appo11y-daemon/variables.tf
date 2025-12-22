variable "environment_id" {
  description = "String to uniquely identify this environment, amongst others."
  type        = string
  default     = "demo"
}

variable "owner" {
  description = "String to identify you; this will be used in tags and resource names to easily show who owns the resource(s)."
  type = string
}

variable "grafana_cloud_otlp_endpoint" {
  description = "Grafana Cloud OTLP endpoint (e.g., https://otlp-gateway-prod-us-central-0.grafana.net/otlp)"
  type        = string
}

variable "grafana_cloud_instance_id" {
  description = "Grafana Cloud instance ID for authentication"
  type        = string
}

variable "grafana_cloud_api_key" {
  description = "Grafana Cloud API key for authentication"
  type        = string
  sensitive   = true
}
