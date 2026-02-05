variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-dotnet-test"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "UK South"
}

variable "prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "dotnetapp"
}

variable "vm_count" {
  description = "Number of VMs to create"
  type        = number
  default     = 3
}

variable "vm_size" {
  description = "Size of the VMs"
  type        = string
  default     = "Standard_B2s"
}

variable "admin_username" {
  description = "Admin username for VMs"
  type        = string
  default     = "azureuser"
}

variable "admin_password" {
  description = "Admin password for VMs"
  type        = string
  sensitive   = true
}

variable "allowed_ip" {
  description = "IP address allowed to access the VMs (RDP and HTTP)"
  type        = string
}

variable "grafana_cloud_cloud_access_policy_token" {
  description = "Grafana Cloud Access Policy Token"
  type        = string
  sensitive   = true
}

variable "grafana_cloud_hosted_metrics_id" {
  description = "Grafana Cloud Hosted Metrics ID"
  type        = string
}

variable "grafana_cloud_hosted_metrics_url" {
  description = "Grafana Cloud Hosted Metrics URL"
  type        = string
}

variable "grafana_cloud_hosted_logs_id" {
  description = "Grafana Cloud Hosted Logs ID"
  type        = string
}

variable "grafana_cloud_hosted_logs_url" {
  description = "Grafana Cloud Hosted Logs URL"
  type        = string
}

variable "grafana_cloud_fm_url" {
  description = "Grafana Cloud Fleet Management URL"
  type        = string
}

variable "grafana_cloud_fm_hosted_id" {
  description = "Grafana Cloud Fleet Management Hosted ID"
  type        = string
}

variable "grafana_cloud_otlp_user_id" {
  description = "Grafana Cloud user ID in OpenTelemetry"
  type        = string
}

variable "cheese_app_release_tag" {
  description = "GitHub release tag for the cheese-app release in monodot/dotnet-playground"
  type        = string
  default     = "v0.3.1" # Adds Redis/StackExchange
}

variable "service_namespace" {
  description = "Service namespace for OpenTelemetry resource attributes"
  type        = string
  default     = "cheeses"
}

variable "deployment_environment" {
  description = "Deployment environment for OpenTelemetry resource attributes"
  type        = string
  default     = "production-demo"
}
