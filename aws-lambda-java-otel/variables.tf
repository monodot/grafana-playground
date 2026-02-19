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

variable "adot_layer_arn" {
  description = "ARN of the AWS ADOT Java Lambda layer. Find the latest version at https://aws-otel.github.io/docs/getting-started/lambda/lambda-java"
  type        = string
  default     = "arn:aws:lambda:us-east-1:901920570463:layer:aws-otel-java-agent-amd64-ver-1-32-0:6" # "arn:aws:lambda:us-east-1:615299751070:layer:AWSOpenTelemetryDistroJava:9"
}
