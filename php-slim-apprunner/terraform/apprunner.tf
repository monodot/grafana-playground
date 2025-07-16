resource "aws_ecr_repository" "this" {
  name = "${var.service_namespace}-${var.environment_id}/app"

  tags = {
    Name = "${var.service_namespace}-${var.environment_id}-app"
  }
}

resource "aws_iam_role" "apprunner_ecr_access" {
  name = "AppRunnerECRAccessRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "build.apprunner.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "apprunner_ecr_access_readonly" {
  role       = aws_iam_role.apprunner_ecr_access.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_apprunner_service" "this" {
  service_name = "${var.service_namespace}-app-${var.environment_id}"

  source_configuration {
    authentication_configuration {
      access_role_arn = aws_iam_role.apprunner_ecr_access.arn
    }
    image_repository {
      image_configuration {
        port = "8080"
        runtime_environment_variables = {
          OTEL_PHP_AUTOLOAD_ENABLED   = "true"  # mandatory
          OTEL_LOG_LEVEL              = "debug" # default is "info", cranking it up to "debug" for more verbose logging
          OTEL_EXPORTER_OTLP_ENDPOINT = var.otlp_endpoint
          OTEL_EXPORTER_OTLP_HEADERS  = var.otlp_headers
          OTEL_EXPORTER_OTLP_PROTOCOL = "http/protobuf"
          OTEL_LOGS_EXPORTER          = "otlp"
          OTEL_RESOURCE_ATTRIBUTES    = var.otlp_resource_attributes
        }
      }
      image_identifier      = "${aws_ecr_repository.this.repository_url}:latest" # "public.ecr.aws/aws-containers/hello-app-runner:latest"
      image_repository_type = "ECR"
    }
    auto_deployments_enabled = false
  }

  health_check_configuration {
    path     = "/health"
    protocol = "HTTP"
  }

  instance_configuration {
    cpu    = "1024" # 256|512|1024|2048|4096|(0.25|0.5|1|2|4)
    memory = "2048"
  }

  tags = {
    Name = "${var.service_namespace}-app-${var.environment_id}"
  }
}
