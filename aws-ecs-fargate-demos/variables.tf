variable "environment_id" {
  type    = string
  default = "demo"
}

variable "loki_endpoint" {
  type    = string
  default = "https://123456:aaaaaaaaaa@logs-prod-008.grafana.net/loki/api/v1/push"
}

variable "fluent_bit_image" {
  type    = string
  default = "grafana/fluent-bit-plugin-loki:2.8.1-amd64"
}

variable "service_namespace" {
  type    = string
  default = "ecs-fargate-demos"
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

variable "grafana_cloud_logs_instance_id" {
  description = "Grafana Cloud Logs instance ID for Firehose delivery"
  type        = string
}

variable "grafana_cloud_access_policy_token" {
  description = "Grafana Cloud Logs access policy token for Firehose delivery"
  type        = string
}
