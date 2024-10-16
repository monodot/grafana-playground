variable "loki_endpoint" {
  type    = string
  default = "https://logs-prod-008.grafana.net/loki/api/v1/push"
}

variable "prometheus_endpoint" {
  type    = string
  default = "https://prometheus-us-central1.grafana.net/api/prom/push"
}

variable "loki_username" {
  type    = string
  default = "123456"
}

variable "loki_password" {
  type    = string
  default = "aaaaaaaaaa"
}

variable "prometheus_username" {
  type    = string
  default = "123456"
}

variable "prometheus_password" {
  type    = string
  default = "aaaaaaaaaa"
}
