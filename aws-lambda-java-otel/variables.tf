variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "function_name" {
  description = "Base name for the Lambda function and related resources"
  type        = string
  default     = "order-handler"
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
