variable "app_name" {
  description = "Name of the application"
  type        = string
  default     = "alloy-cw-firehose-demo"
}

variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
  default     = "loki-structured-metadata-demo"
}

variable "alloy_instance_count" {
  description = "Number of EC2 instances to create (1 or 2)"
  type        = number
  default     = 1
  validation {
    condition     = var.alloy_instance_count == 1 || var.alloy_instance_count == 2
    error_message = "Instance count must be either 1 or 2."
  }
}

variable "alloy_instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "loki_endpoint" {
  description = "Loki endpoint URL"
  type        = string
  default     = "https://loki:3100/loki/api/v1/push"
}

variable "loki_username" {
  description = "Username for Loki authentication"
  type        = string
  default     = "123456"
}

variable "grafana_cloud_api_key" {
  description = "Password for Loki authentication"
  type        = string
  default     = "glc_xxxxxxx"
  sensitive   = true
}

variable "otlp_username" {
  description = "Username for OTLP endpoint"
  type        = string
  default     = "123"
}

variable "otlp_endpoint" {
  description = "OTLP endpoint URL"
  type        = string
  default     = "https://otlp-gateway.example.com/otlp"
}
