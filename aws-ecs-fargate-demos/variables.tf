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
