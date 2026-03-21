locals {
  # When the sidecar collector layer is present, the agent routes to localhost.
  # Otherwise the agent exports directly (or drops if no endpoint is set).
  use_collector     = var.collector_layer_arn != null
  use_direct_export = !local.use_collector && var.otel_exporter_otlp_endpoint != ""

  layers = compact([
    var.java_agent_layer_arn,
    var.collector_layer_arn,
    var.collector_config_layer_arn,
    var.lambda_insights_layer_arn,
  ])

  # Environment variables contributed by the Java agent (only when it is present).
  agent_env = var.java_agent_layer_arn != null ? {
    AWS_LAMBDA_EXEC_WRAPPER                              = "/opt/otel-handler"
    OTEL_SERVICE_NAME                                    = var.name_prefix
    OTEL_TRACES_EXPORTER                                 = var.otel_traces_exporter
    OTEL_METRICS_EXPORTER                                = var.otel_metrics_exporter
    OTEL_LOGS_EXPORTER                                   = var.otel_logs_exporter
    OTEL_PROPAGATORS                                     = "tracecontext,baggage,xray"
    OTEL_INSTRUMENTATION_AWS_LAMBDA_FLUSH_TIMEOUT        = "10000"
    OTEL_INSTRUMENTATION_COMMON_DEFAULT_ENABLED          = "true"
  } : {}

  # When the sidecar collector is active, tell the agent to send to localhost
  # and pass the Grafana Cloud credentials for the collector to use.
  collector_env = local.use_collector ? {
    OTEL_EXPORTER_OTLP_ENDPOINT             = "http://localhost:4318"
    OTEL_EXPORTER_OTLP_PROTOCOL             = "http/protobuf"
    OPENTELEMETRY_COLLECTOR_CONFIG_URI      = "file:///opt/collector-config/config.yaml"
    GRAFANA_CLOUD_OTLP_ENDPOINT             = var.grafana_cloud_otlp_endpoint
    GRAFANA_CLOUD_AUTH                      = var.grafana_cloud_auth
  } : {}

  # For direct export (no sidecar), point the agent straight at the endpoint.
  direct_env = local.use_direct_export ? {
    OTEL_EXPORTER_OTLP_ENDPOINT = var.otel_exporter_otlp_endpoint
    OTEL_EXPORTER_OTLP_PROTOCOL = "http/protobuf"
  } : {}

  # Only inject the auth header when it is non-empty (external collector has no header).
  direct_headers_env = (local.use_direct_export && var.otel_exporter_otlp_headers != "") ? {
    OTEL_EXPORTER_OTLP_HEADERS = var.otel_exporter_otlp_headers
  } : {}

  env_vars = merge(
    local.agent_env,
    local.collector_env,
    local.direct_env,
    local.direct_headers_env,
  )
}

resource "aws_lambda_function" "this" {
  function_name    = var.name_prefix
  role             = var.execution_role_arn
  runtime          = "java21"
  handler          = "com.example.AuthzHandler"
  memory_size      = var.memory_size
  timeout          = 30
  filename         = var.jar_path
  source_code_hash = var.source_code_hash

  # publish = true is required for SnapStart; harmless when snapstart_enabled = false.
  publish = var.snapstart_enabled

  layers = local.layers

  dynamic "snap_start" {
    for_each = var.snapstart_enabled ? [1] : []
    content {
      apply_on = "PublishedVersions"
    }
  }

  dynamic "vpc_config" {
    for_each = var.vpc_subnet_ids != null ? [1] : []
    content {
      subnet_ids         = var.vpc_subnet_ids
      security_group_ids = var.vpc_security_group_ids
    }
  }

  environment {
    variables = local.env_vars
  }

  tags = var.tags
}

# ── SnapStart alias ───────────────────────────────────────────────────────────
# Points to the most recently published numeric version so that the Function URL
# and SnapStart are wired together correctly.

resource "aws_lambda_alias" "snapstart" {
  count            = var.snapstart_enabled ? 1 : 0
  name             = "live"
  function_name    = aws_lambda_function.this.function_name
  function_version = aws_lambda_function.this.version
}

# ── Function URLs ─────────────────────────────────────────────────────────────

resource "aws_lambda_function_url" "latest" {
  count              = var.snapstart_enabled ? 0 : 1
  function_name      = aws_lambda_function.this.function_name
  authorization_type = "NONE"

  cors {
    allow_origins = ["*"]
    allow_methods = ["POST"]
    allow_headers = ["Content-Type"]
    max_age       = 300
  }
}

resource "aws_lambda_function_url" "snapstart" {
  count              = var.snapstart_enabled ? 1 : 0
  function_name      = aws_lambda_function.this.function_name
  qualifier          = aws_lambda_alias.snapstart[0].name
  authorization_type = "NONE"

  cors {
    allow_origins = ["*"]
    allow_methods = ["POST"]
    allow_headers = ["Content-Type"]
    max_age       = 300
  }
}

# ── Permissions ───────────────────────────────────────────────────────────────

resource "aws_lambda_permission" "url_invoke" {
  count                  = var.snapstart_enabled ? 0 : 1
  statement_id           = "AllowFunctionURLInvoke"
  action                 = "lambda:InvokeFunctionUrl"
  function_name          = aws_lambda_function.this.function_name
  principal              = "*"
  function_url_auth_type = "NONE"
}

resource "aws_lambda_permission" "url_invoke_function" {
  count         = var.snapstart_enabled ? 0 : 1
  statement_id  = "AllowFunctionURLInvokeFunction"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "*"
}

resource "aws_lambda_permission" "url_invoke_alias" {
  count                  = var.snapstart_enabled ? 1 : 0
  statement_id           = "AllowFunctionURLInvoke"
  action                 = "lambda:InvokeFunctionUrl"
  function_name          = aws_lambda_function.this.function_name
  qualifier              = aws_lambda_alias.snapstart[0].name
  principal              = "*"
  function_url_auth_type = "NONE"
}

resource "aws_lambda_permission" "url_invoke_alias_function" {
  count         = var.snapstart_enabled ? 1 : 0
  statement_id  = "AllowFunctionURLInvokeFunction"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  qualifier     = aws_lambda_alias.snapstart[0].name
  principal     = "*"
}
