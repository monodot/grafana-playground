resource "aws_ecs_task_definition" "alloy_task_def" {
  family             = "grafana-alloy-${var.environment_id}"
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name              = "grafana-alloy-container"
      image             = "docker.io/grafana/alloy:latest"
      memoryReservation = 512
      essential         = true

      entryPoint = ["/bin/sh", "-c"]
      command = [
        "printf '%s' \"$ALLOY_CONFIG\" > /etc/alloy/config.alloy && exec /bin/alloy run --server.http.listen-addr=0.0.0.0:12345 --storage.path=/var/lib/alloy/data /etc/alloy/config.alloy"
      ]

      environment = [
        {
          name  = "GRAFANA_CLOUD_OTLP_ENDPOINT"
          value = var.grafana_cloud_otlp_endpoint
        },
        {
          name  = "GRAFANA_CLOUD_INSTANCE_ID"
          value = var.grafana_cloud_instance_id
        },
        {
          name  = "GRAFANA_CLOUD_API_KEY"
          value = var.grafana_cloud_api_key
        }
      ]

      secrets = [
        {
          name      = "ALLOY_CONFIG"
          valueFrom = aws_ssm_parameter.alloy_config.arn
        }
      ]

      portMappings = [
        {
          containerPort = 4317
          hostPort      = 4317
          protocol      = "tcp"
          name          = "alloy-otlp-grpc"
        },
        {
          containerPort = 4318
          hostPort      = 4318
          protocol      = "tcp"
          name          = "alloy-otlp-http"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.alloy_logs.name
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "alloy"
        }
      }
    }
  ])

  tags = {
    Name = "grafana-alloy-${var.environment_id}"
  }
}

# ECS service running Alloy as daemon (one per EC2 host)
resource "aws_ecs_service" "alloy_daemon" {
  name                = "alloy-daemon-${var.environment_id}"
  cluster             = aws_ecs_cluster.workshop.id
  task_definition     = aws_ecs_task_definition.alloy_task_def.arn
  scheduling_strategy = "DAEMON"

  tags = {
    Name = "alloy-daemon-service-${var.environment_id}"
  }
}
