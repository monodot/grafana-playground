# ── Build the function JAR ────────────────────────────────────────────────────

resource "null_resource" "build_jar" {
  triggers = {
    pom_hash     = filemd5("${path.module}/../function/pom.xml")
    handler_hash = filemd5("${path.module}/../function/src/main/java/com/example/AuthzHandler.java")
  }

  provisioner "local-exec" {
    command = "cd ${path.module}/../function && mvn package -q"
  }
}

# ── IAM — shared Lambda execution role ───────────────────────────────────────

resource "aws_iam_role" "lambda" {
  name = "${var.name_prefix}-lambda-exec"
  tags = local.common_tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_insights" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLambdaInsightsExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "lambda_xray" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

# Allow the role to use the OTel layer ARNs.
resource "aws_iam_role_policy" "lambda_layers" {
  name = "${var.name_prefix}-layer-access"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["lambda:GetLayerVersion"]
      Resource = [
        "${var.java_agent_layer_arn}",
        "${var.collector_layer_arn}",
        "${var.lambda_insights_layer_arn}",
      ]
    }]
  })
}

# ── Collector config Lambda layer ─────────────────────────────────────────────
# Packages collector-config/lambda-layer.yaml into a layer at the path the ADOT
# collector extension expects: /opt/collector-config/config.yaml

data "archive_file" "collector_config_layer" {
  type        = "zip"
  output_path = "${path.module}/collector-config-layer.zip"

  source {
    content  = file("${path.module}/../collector-config/lambda-layer.yaml")
    filename = "collector-config/config.yaml"
  }
}

resource "aws_lambda_layer_version" "collector_config" {
  layer_name               = "${var.name_prefix}-otel-collector-config"
  # tags                     = local.common_tags
  filename                 = data.archive_file.collector_config_layer.output_path
  source_code_hash         = data.archive_file.collector_config_layer.output_base64sha256
  compatible_runtimes      = ["java21"]
  compatible_architectures = ["x86_64"]
}

# ── VPC networking for config 5 ───────────────────────────────────────────────

resource "aws_security_group" "config_5_lambda" {
  name        = "${var.name_prefix}-c5-lambda"
  description = "config_5 Lambda - egress only; ingress from collector SG on 4317/4318"
  vpc_id      = aws_vpc.this.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}


# ── Shared module arguments ───────────────────────────────────────────────────
# These are repeated per module call below; Terraform doesn't support passing
# a map of arguments to a module, so each call is explicit for clarity.
#
# Common args for every variant:
#   execution_role_arn        = aws_iam_role.lambda.arn
#   jar_path                  = local.jar_path
#   source_code_hash          = local.source_code_hash
#   lambda_insights_layer_arn = var.lambda_insights_layer_arn
#   depends_on                = [null_resource.build_jar]
#
# Collector-layer variants also share:
#   collector_layer_arn        = var.collector_layer_arn
#   collector_config_layer_arn = local.collector_config_layer_arn
#   grafana_cloud_otlp_endpoint = var.grafana_cloud_otlp_endpoint
#   grafana_cloud_auth          = local.grafana_auth
#   otel_traces_exporter       = "otlp"
#   otel_metrics_exporter      = "otlp"
#   otel_logs_exporter         = "otlp"

# ── Config 1: True baseline ───────────────────────────────────────────────────

module "config_1" {
  source = "./modules/lambda-demo-variant"

  name_prefix               = "${var.name_prefix}-c1-baseline"
  jar_path                  = local.jar_path
  source_code_hash          = local.source_code_hash
  execution_role_arn        = aws_iam_role.lambda.arn
  lambda_insights_layer_arn = var.lambda_insights_layer_arn

  tags       = local.common_tags
  depends_on = [null_resource.build_jar]
}

# ── Config 2: OTel SDK loaded, all exporters disabled ────────────────────────

module "config_2" {
  source = "./modules/lambda-demo-variant"

  name_prefix               = "${var.name_prefix}-c2-sdk"
  jar_path                  = local.jar_path
  source_code_hash          = local.source_code_hash
  execution_role_arn        = aws_iam_role.lambda.arn
  lambda_insights_layer_arn = var.lambda_insights_layer_arn
  java_agent_layer_arn      = var.java_agent_layer_arn
  otel_traces_exporter      = "none"
  otel_metrics_exporter     = "none"
  otel_logs_exporter        = "none"

  tags       = local.common_tags
  depends_on = [null_resource.build_jar]
}

# ── Config 3: Direct export to Grafana Cloud ─────────────────────────────────

module "config_3" {
  source = "./modules/lambda-demo-variant"

  name_prefix                 = "${var.name_prefix}-c3-direct"
  jar_path                    = local.jar_path
  source_code_hash            = local.source_code_hash
  execution_role_arn          = aws_iam_role.lambda.arn
  lambda_insights_layer_arn   = var.lambda_insights_layer_arn
  java_agent_layer_arn        = var.java_agent_layer_arn
  otel_traces_exporter        = "otlp"
  otel_metrics_exporter       = "otlp"
  otel_logs_exporter          = "otlp"
  otel_exporter_otlp_endpoint = var.grafana_cloud_otlp_endpoint
  otel_exporter_otlp_headers  = local.grafana_otlp_headers

  tags       = local.common_tags
  depends_on = [null_resource.build_jar]
}

# ── Config 4: Collector Lambda Layer (full signals) ───────────────────────────

module "config_4" {
  source = "./modules/lambda-demo-variant"

  name_prefix                 = "${var.name_prefix}-c4-col-layer"
  jar_path                    = local.jar_path
  source_code_hash            = local.source_code_hash
  execution_role_arn          = aws_iam_role.lambda.arn
  lambda_insights_layer_arn   = var.lambda_insights_layer_arn
  java_agent_layer_arn        = var.java_agent_layer_arn
  collector_layer_arn         = var.collector_layer_arn
  collector_config_layer_arn  = local.collector_config_layer_arn
  otel_traces_exporter        = "otlp"
  otel_metrics_exporter       = "otlp"
  otel_logs_exporter          = "otlp"
  grafana_cloud_otlp_endpoint = var.grafana_cloud_otlp_endpoint
  grafana_cloud_auth          = local.grafana_auth

  tags       = local.common_tags
  depends_on = [null_resource.build_jar]
}

# ── Config 5: External ECS Fargate collector ──────────────────────────────────

module "config_5" {
  source = "./modules/lambda-demo-variant"

  name_prefix                 = "${var.name_prefix}-c5-ext-col"
  jar_path                    = local.jar_path
  source_code_hash            = local.source_code_hash
  execution_role_arn          = aws_iam_role.lambda.arn
  lambda_insights_layer_arn   = var.lambda_insights_layer_arn
  java_agent_layer_arn        = var.java_agent_layer_arn
  otel_traces_exporter        = "otlp"
  otel_metrics_exporter       = "otlp"
  otel_logs_exporter          = "otlp"
  otel_exporter_otlp_endpoint = "http://${aws_lb.ecs_collector.dns_name}:4318"
  vpc_subnet_ids              = aws_subnet.private[*].id
  vpc_security_group_ids      = [aws_security_group.config_5_lambda.id]

  tags       = local.common_tags
  depends_on = [null_resource.build_jar]
}

# # ── Config 6: Collector Layer — metrics only ──────────────────────────────────
#
# module "config_6" {
#   source = "./modules/lambda-demo-variant"
#
#   name_prefix                 = "${var.name_prefix}-c6-metrics"
#   jar_path                    = local.jar_path
#   source_code_hash            = local.source_code_hash
#   execution_role_arn          = aws_iam_role.lambda.arn
#   lambda_insights_layer_arn   = var.lambda_insights_layer_arn
#   java_agent_layer_arn        = var.java_agent_layer_arn
#   collector_layer_arn         = var.collector_layer_arn
#   collector_config_layer_arn  = local.collector_config_layer_arn
#   otel_traces_exporter        = "none"
#   otel_metrics_exporter       = "otlp"
#   otel_logs_exporter          = "none"
#   grafana_cloud_otlp_endpoint = var.grafana_cloud_otlp_endpoint
#   grafana_cloud_auth          = local.grafana_auth
#
#   tags       = local.common_tags
#   depends_on = [null_resource.build_jar]
# }
#
# # ── Config 7: Collector Layer — traces only ───────────────────────────────────
#
# module "config_7" {
#   source = "./modules/lambda-demo-variant"
#
#   name_prefix                 = "${var.name_prefix}-c7-traces"
#   jar_path                    = local.jar_path
#   source_code_hash            = local.source_code_hash
#   execution_role_arn          = aws_iam_role.lambda.arn
#   lambda_insights_layer_arn   = var.lambda_insights_layer_arn
#   java_agent_layer_arn        = var.java_agent_layer_arn
#   collector_layer_arn         = var.collector_layer_arn
#   collector_config_layer_arn  = local.collector_config_layer_arn
#   otel_traces_exporter        = "otlp"
#   otel_metrics_exporter       = "none"
#   otel_logs_exporter          = "none"
#   grafana_cloud_otlp_endpoint = var.grafana_cloud_otlp_endpoint
#   grafana_cloud_auth          = local.grafana_auth
#
#   tags       = local.common_tags
#   depends_on = [null_resource.build_jar]
# }
#
# # ── Config 8: Collector Layer — 128 MB ────────────────────────────────────────
#
# module "config_8" {
#   source = "./modules/lambda-demo-variant"
#
#   name_prefix                 = "${var.name_prefix}-c8-128mb"
#   jar_path                    = local.jar_path
#   source_code_hash            = local.source_code_hash
#   execution_role_arn          = aws_iam_role.lambda.arn
#   lambda_insights_layer_arn   = var.lambda_insights_layer_arn
#   java_agent_layer_arn        = var.java_agent_layer_arn
#   collector_layer_arn         = var.collector_layer_arn
#   collector_config_layer_arn  = local.collector_config_layer_arn
#   otel_traces_exporter        = "otlp"
#   otel_metrics_exporter       = "otlp"
#   otel_logs_exporter          = "otlp"
#   grafana_cloud_otlp_endpoint = var.grafana_cloud_otlp_endpoint
#   grafana_cloud_auth          = local.grafana_auth
#   memory_size                 = 128
#
#   tags       = local.common_tags
#   depends_on = [null_resource.build_jar]
# }
#
# # ── Config 9: Collector Layer — 1024 MB ───────────────────────────────────────
#
# module "config_9" {
#   source = "./modules/lambda-demo-variant"
#
#   name_prefix                 = "${var.name_prefix}-c9-1024mb"
#   jar_path                    = local.jar_path
#   source_code_hash            = local.source_code_hash
#   execution_role_arn          = aws_iam_role.lambda.arn
#   lambda_insights_layer_arn   = var.lambda_insights_layer_arn
#   java_agent_layer_arn        = var.java_agent_layer_arn
#   collector_layer_arn         = var.collector_layer_arn
#   collector_config_layer_arn  = local.collector_config_layer_arn
#   otel_traces_exporter        = "otlp"
#   otel_metrics_exporter       = "otlp"
#   otel_logs_exporter          = "otlp"
#   grafana_cloud_otlp_endpoint = var.grafana_cloud_otlp_endpoint
#   grafana_cloud_auth          = local.grafana_auth
#   memory_size                 = 1024
#
#   tags       = local.common_tags
#   depends_on = [null_resource.build_jar]
# }
#
# # ── Config 10: Collector Layer + SnapStart ────────────────────────────────────
#
# module "config_10" {
#   source = "./modules/lambda-demo-variant"
#
#   name_prefix                 = "${var.name_prefix}-c10-snapstart"
#   jar_path                    = local.jar_path
#   source_code_hash            = local.source_code_hash
#   execution_role_arn          = aws_iam_role.lambda.arn
#   lambda_insights_layer_arn   = var.lambda_insights_layer_arn
#   java_agent_layer_arn        = var.java_agent_layer_arn
#   collector_layer_arn         = var.collector_layer_arn
#   collector_config_layer_arn  = local.collector_config_layer_arn
#   otel_traces_exporter        = "otlp"
#   otel_metrics_exporter       = "otlp"
#   otel_logs_exporter          = "otlp"
#   grafana_cloud_otlp_endpoint = var.grafana_cloud_otlp_endpoint
#   grafana_cloud_auth          = local.grafana_auth
#   snapstart_enabled           = true
#
#   tags       = local.common_tags
#   depends_on = [null_resource.build_jar]
# }
#
# # ── Config 11: Direct export + SnapStart ──────────────────────────────────────
#
# module "config_11" {
#   source = "./modules/lambda-demo-variant"
#
#   name_prefix                 = "${var.name_prefix}-c11-direct-snap"
#   jar_path                    = local.jar_path
#   source_code_hash            = local.source_code_hash
#   execution_role_arn          = aws_iam_role.lambda.arn
#   lambda_insights_layer_arn   = var.lambda_insights_layer_arn
#   java_agent_layer_arn        = var.java_agent_layer_arn
#   otel_traces_exporter        = "otlp"
#   otel_metrics_exporter       = "otlp"
#   otel_logs_exporter          = "otlp"
#   otel_exporter_otlp_endpoint = var.grafana_cloud_otlp_endpoint
#   otel_exporter_otlp_headers  = local.grafana_otlp_headers
#   snapstart_enabled           = true
#
#   tags       = local.common_tags
#   depends_on = [null_resource.build_jar]
# }
