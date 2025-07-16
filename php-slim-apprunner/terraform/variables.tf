variable "environment_id" {
  description = "Unique identifier for the environment, e.g., 'demo', 'acme123', etc."
  type        = string
  default     = "demo"
}

variable "service_namespace" {
  description = "Namespace for resources created in this configuration, adds a prefix to resource names"
  type        = string
  default     = "php-demo-apprunner"
}

variable "otlp_endpoint" {
  description = "Grafana Cloud OTLP endpoint for metrics and traces, e.g. https://otlp-gateway-prod-gb-south-0.grafana.net/otlp"
  type        = string
}

variable "otlp_headers" {
  description = "Formatted headers for Grafana Cloud OTLP endpoint, e.g. 'Authorization=Basic NDMy....A9'"
  type        = string
}

variable "otlp_resource_attributes" {
  description = "Resource attributes for OTLP, e.g. 'service.name=my-app,service.namespace=my-application-group,deployment.environment=production'"
  type        = string
  default     = "service.name=rolldice,service.namespace=php-demo-apprunner,deployment.environment=production" # service.instance.id?
}
