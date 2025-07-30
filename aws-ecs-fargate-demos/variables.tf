variable "environment_id" {
  description = "Unique identifier for the environment, e.g., 'demo', 'acme123', etc."
  type        = string
  default     = "demo"
}

variable "service_namespace" {
  type    = string
  default = "ecs-fargate-demos"
}

variable "service_name_alloy_sidecar" {
  type    = string
  default = "ecs-demo-alloy-sidecar"
}

variable "loki_endpoint_with_auth" {
  description = "Grafana Cloud Loki endpoint containing basic authentication details"
  type        = string
  # default = "https://123456:aaaaaaaaaa@logs-prod-008.grafana.net/loki/api/v1/push"
}

variable "prometheus_remote_write_url" {
  description = "Grafana Cloud Prometheus remote write URL, e.g. https://prometheus-prod-05-gb-south-0.grafana.net/api/prom/push"
  type        = string
}

variable "prometheus_username" {
  description = "Grafana Cloud Prometheus username"
  type        = string
}

variable "fluent_bit_image" {
  type    = string
  default = "grafana/fluent-bit-plugin-loki:3.5"
}

variable "firehose_log_delivery_errors" {
  description = "Enable Firehose delivery errors to CloudWatch Logs"
  type        = bool
  default     = false
}

variable "grafana_cloud_firehose_target_endpoint" {
  description = "Grafana Cloud Firehose target endpoint for logs delivery"
  type        = string
}

variable "loki_username" {
  description = "Grafana Cloud Logs instance ID for Firehose delivery"
  type        = string
}

variable "grafana_cloud_access_policy_token" {
  description = "Grafana Cloud access policy token with permissions to write metrics and logs"
  type        = string
}

variable "grafana_cloud_otlp_endpoint" {
  type = string
}

variable "grafana_cloud_instance_id" {
  type = string
}
