variable "name_prefix" {
  description = "Unique name for this Lambda variant. Used as the function name and resource prefix."
  type        = string
}

variable "jar_path" {
  description = "Local path to the shaded JAR produced by `mvn package`"
  type        = string
}

variable "source_code_hash" {
  description = "Hash of the function source, used to trigger redeployment. Pass the value from the root null_resource triggers."
  type        = string
}

variable "execution_role_arn" {
  description = "IAM role ARN for the Lambda execution role"
  type        = string
}

variable "memory_size" {
  description = "Lambda memory in MB"
  type        = number
  default     = 512
}

variable "snapstart_enabled" {
  description = "Enable SnapStart. Requires java21 runtime. Creates a published version and a 'live' alias."
  type        = bool
  default     = false
}

# ── Layers ────────────────────────────────────────────────────────────────────

variable "java_agent_layer_arn" {
  description = "ARN of the OTel Java agent layer. Null = no instrumentation."
  type        = string
  default     = null
}

variable "collector_layer_arn" {
  description = "ARN of the OTel Collector Lambda layer. Null = no sidecar collector."
  type        = string
  default     = null
}

variable "collector_config_layer_arn" {
  description = "ARN of the layer containing /opt/collector-config/config.yaml. Required when collector_layer_arn is set."
  type        = string
  default     = null
}

variable "lambda_insights_layer_arn" {
  description = "ARN of the CloudWatch Lambda Insights extension layer"
  type        = string
}

# ── Export routing ────────────────────────────────────────────────────────────
#
# Exactly one export mode should be active per variant:
#   A) collector_layer_arn set   → agent sends to localhost:4318; collector forwards
#   B) otel_exporter_otlp_endpoint set → agent sends directly to that endpoint
#   C) neither                   → agent runs but drops all signals (SDK-overhead-only)

variable "otel_exporter_otlp_endpoint" {
  description = "Direct OTLP endpoint for the Java agent (e.g. Grafana Cloud or external collector URL). Ignored when collector_layer_arn is set."
  type        = string
  default     = ""
}

variable "otel_exporter_otlp_headers" {
  description = "OTLP request headers for direct export, e.g. 'Authorization=Basic xxx'. Ignored when collector_layer_arn is set."
  type        = string
  default     = ""
  sensitive   = true
}

variable "otel_traces_exporter" {
  description = "'otlp' or 'none'. Controls whether the Java agent exports traces."
  type        = string
  default     = "none"

  validation {
    condition     = contains(["otlp", "none"], var.otel_traces_exporter)
    error_message = "Must be 'otlp' or 'none'."
  }
}

variable "otel_metrics_exporter" {
  description = "'otlp' or 'none'. Controls whether the Java agent exports metrics."
  type        = string
  default     = "none"

  validation {
    condition     = contains(["otlp", "none"], var.otel_metrics_exporter)
    error_message = "Must be 'otlp' or 'none'."
  }
}

variable "otel_logs_exporter" {
  description = "'otlp' or 'none'. Controls whether the Java agent exports logs."
  type        = string
  default     = "none"

  validation {
    condition     = contains(["otlp", "none"], var.otel_logs_exporter)
    error_message = "Must be 'otlp' or 'none'."
  }
}

# Used only when collector_layer_arn is set — passed to the sidecar collector as env vars.
variable "grafana_cloud_otlp_endpoint" {
  description = "Grafana Cloud OTLP endpoint for the sidecar collector to forward to"
  type        = string
  default     = ""
}

variable "grafana_cloud_auth" {
  description = "base64(instanceId:token) for Grafana Cloud Basic auth, consumed by the sidecar collector"
  type        = string
  default     = ""
  sensitive   = true
}

variable "vpc_subnet_ids" {
  description = "Private subnet IDs to attach the Lambda to. Null = Lambda runs outside VPC."
  type        = list(string)
  default     = null
}

variable "vpc_security_group_ids" {
  description = "Security group IDs for the Lambda VPC config. Required when vpc_subnet_ids is set."
  type        = list(string)
  default     = null
}

variable "tags" {
  type    = map(string)
  default = {}
}
