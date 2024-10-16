resource "aws_ecs_task_definition" "grafana_alloy" {
  family = "${data.external.whoami.result.user}-grafana-alloy-demo"
  container_definitions = jsonencode([
    {
      name              = "alloy"
      image             = "grafana/alloy:latest"
      memoryReservation = 50
      essential         = true
      command = [
        "run",
        "--server.http.listen-addr=0.0.0.0:12345",
        "--storage.path=/var/lib/alloy/data",
        "/etc/alloy/config.alloy",
      ]
      environment = [
        {
          name  = "GRAFANA_CLOUD_LOGS_URL"
          value = var.loki_endpoint
        },
        {
          name  = "GRAFANA_CLOUD_LOGS_ID",
          value = var.loki_username
        },
        {
          name  = "GRAFANA_CLOUD_API_KEY",
          value = var.loki_password
        }
      ]
      mountPoints = [
        {
          sourceVolume  = "alloy"
          containerPath = "/etc/alloy"
          readOnly      = true
        },
        {
          sourceVolume  = "docker"
          containerPath = "/var/run/docker.sock"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.main.name
          "awslogs-region"        = "us-west-2"
          "awslogs-stream-prefix" = "ecs-alloy"
        }
      }
    }
  ])

  volume {
    name      = "alloy"
    host_path = "/etc/alloy"
  }
  volume {
    name      = "docker"
    host_path = "/var/run/docker.sock"
  }
}

# Run Alloy as a daemon on each node in the ECS cluster
resource "aws_ecs_service" "grafana_alloy" {
  name                = "${data.external.whoami.result.user}-loki-ec2-grafana-alloy"
  cluster             = aws_ecs_cluster.main.id
  task_definition     = aws_ecs_task_definition.grafana_alloy.arn
  scheduling_strategy = "DAEMON"
}
