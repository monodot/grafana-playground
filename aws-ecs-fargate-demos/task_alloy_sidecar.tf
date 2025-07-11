resource "aws_cloudwatch_log_group" "alloy_sidecar" {
  name = "${var.service_namespace}-alloy-sidecar-${var.environment_id}"
}

resource "aws_ecs_task_definition" "alloy_sidecar" {
  family                   = "${var.service_namespace}-alloy-sidecar-task-def-${var.environment_id}"
  memory                   = "512"
  cpu                      = "256"
  execution_role_arn       = aws_iam_role.task_execution.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  volume {
    name = "alloy-config"
  }

  container_definitions = jsonencode([
    // FireLens container for routing logs to Alloy
    {
      essential         = true
      image             = var.fluent_bit_image
      name              = "log_router"
      memoryReservation = 50
      essential         = true
      mountPoints       = []
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.alloy_sidecar.name
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "log-router"
        }
      }
      firelensConfiguration = {
        type = "fluentbit"
        options = {
          enable-ecs-log-metadata = "true"
        }
      }
    },
    {
      name = "sample-app"
      command = [
        "/bin/sh -c \"while true; do sleep 15 ;echo hello from ecs-fargate-alloy-sidecar; done\""
      ]
      entryPoint = [
        "sh",
        "-c"
      ]
      image     = "alpine:3.13"
      essential = true
      dependsOn = [
        {
          containerName = "alloy-sidecar",
          condition     = "HEALTHY"
        }
      ]
      logConfiguration = {
        logDriver = "awsfirelens"
        options = {
          Name       = "grafana-loki"
          LabelKeys  = "container_name,ecs_task_definition,source,ecs_cluster"
          Labels     = "{service_name=\"ecs-fargate-alloy-sidecar\",service_namespace=\"${var.service_namespace}\"}"
          LineFormat = "key_value"
          RemoveKeys = "container_id,ecs_task_arn"
          Url        = "http://localhost:3100/loki/api/v1/push" # Assuming Alloy is running on localhost in the container
        }
      }
    },
    // Container that writes the Alloy configuration to a file
    {
      name      = "config-writer",
      essential = false,
      image     = "busybox:latest",
      memory    = 256,
      command = [
        "sh", "-c",
        "echo \"${replace(file("${path.module}/templates/config_ecs.alloy"), "\"", "\\\"")}\" > /etc/alloy/config.alloy"
      ],
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.alloy_sidecar.name,
          "awslogs-region"        = "us-east-1",
          "awslogs-stream-prefix" = "config-writer"
        }
      },
      mountPoints = [
        {
          sourceVolume  = "alloy-config",
          containerPath = "/etc/alloy"
        }
      ]
    },
    {
      name      = "alloy-sidecar"
      image     = "docker.io/grafana/alloy:latest"
      essential = true

      # Wait for the config-writer container to finish before starting Alloy
      dependsOn = [
        {
          containerName = "config-writer",
          condition     = "COMPLETE"
        }
      ]
      healthCheck = {
        command = [
          "CMD-SHELL",
          "bash -c 'exec 3<>/dev/tcp/localhost/12345 && printf \"GET /-/ready HTTP/1.1\\r\\nHost: localhost\\r\\nConnection: close\\r\\n\\r\\n\" >&3 && read response <&3 && echo $response | grep \"200 OK\" || exit 1'"
        ]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 10
      }

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.alloy_sidecar.name
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "alloy"
        }
      }

      environment = [
        # {
        #   name  = "GRAFANA_CLOUD_OTLP_ENDPOINT",
        #   value = var.grafana_cloud_otlp_endpoint
        # },
        # {
        #   name  = "GRAFANA_CLOUD_INSTANCE_ID",
        #   value = var.grafana_cloud_instance_id
        # },
        # {
        #   name  = "GRAFANA_CLOUD_API_KEY",
        #   value = var.grafana_cloud_access_token
        # },
        {
          name  = "LOKI_ENDPOINT",
          value = var.loki_endpoint
        },
        # {
        #   name  = "GRAFANA_CLOUD_LOGS_USERNAME"
        #   value = var.grafana_cloud_logs_username
        # }
      ],

      mountPoints = [
        {
          sourceVolume  = "alloy-config",
          containerPath = "/etc/alloy"
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "alloy_sidecar" {
  name            = "${var.service_namespace}-alloy-sidecar"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.alloy_sidecar.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [data.aws_subnet.default.id]
    security_groups  = [data.aws_security_group.default.id]
    assign_public_ip = true
  }
}
