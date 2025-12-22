# ECS task definition for telemetrygen (demo application)
resource "aws_ecs_task_definition" "telemetrygen_task_def" {
  family             = "telemetrygen-${var.environment_id}"
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name              = "telemetrygen-container"
      image             = "ghcr.io/open-telemetry/opentelemetry-collector-contrib/telemetrygen:v0.142.0"
      memoryReservation = 128
      essential         = true

      command = [
        "traces",
        "--otlp-endpoint",
        "${aws_instance.ecs_node.private_ip}:4317",
        "--otlp-insecure",
        "--duration",
        "0s",
        "--rate",
        "1",
        "--workers",
        "1",
        "--duration",
        "5m",
      ],

      environment = [
        {
          name  = "OTEL_SERVICE_NAME"
          value = "telemetrygen-demo"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.telemetrygen_logs.name
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "telemetrygen"
        }
      }
    }
  ])

  tags = {
    Name = "telemetrygen-${var.environment_id}"
  }
}

# CloudWatch log group for telemetrygen
resource "aws_cloudwatch_log_group" "telemetrygen_logs" {
  name              = "/ecs/telemetrygen-${var.environment_id}"
  retention_in_days = 7

  tags = {
    Name = "telemetrygen-logs-${var.environment_id}"
  }
}

# ECS service for telemetrygen (single instance)
resource "aws_ecs_service" "telemetrygen" {
  name            = "telemetrygen-${var.environment_id}"
  cluster         = aws_ecs_cluster.workshop.id
  task_definition = aws_ecs_task_definition.telemetrygen_task_def.arn
  desired_count   = 1

  tags = {
    Name = "telemetrygen-service-${var.environment_id}"
  }
}