resource "aws_cloudwatch_log_group" "ecs_events" {
  name = "${var.service_namespace}-ecs-events-${var.environment_id}"
}

data "aws_iam_policy_document" "example_log_policy" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream"
    ]

    resources = [
      "${aws_cloudwatch_log_group.ecs_events.arn}:*"
    ]

    principals {
      type = "Service"
      identifiers = [
        "events.amazonaws.com",
        "delivery.logs.amazonaws.com"
      ]
    }
  }
  statement {
    effect = "Allow"
    actions = [
      "logs:PutLogEvents"
    ]

    resources = [
      "${aws_cloudwatch_log_group.ecs_events.arn}:*:*"
    ]

    principals {
      type = "Service"
      identifiers = [
        "events.amazonaws.com",
        "delivery.logs.amazonaws.com"
      ]
    }

    condition {
      test     = "ArnEquals"
      values   = [aws_cloudwatch_event_rule.ecs_events_to_log.arn]
      variable = "aws:SourceArn"
    }
  }
}

resource "aws_cloudwatch_log_resource_policy" "example" {
  policy_document = data.aws_iam_policy_document.example_log_policy.json
  policy_name     = "ecs-events-log-publishing-policy-${var.environment_id}"
}

resource "aws_cloudwatch_event_rule" "ecs_events_to_log" {
  name        = "${var.service_namespace}-ecs-events-to-cw-${var.environment_id}"
  description = "Capture all ECS events"

  event_pattern = jsonencode({
    source = ["aws.ecs"]
    # detail-type = [
    #   "ECS Task State Change",
    #   "ECS Container Instance State Change",
    #   "ECS Service Action"
    # ]
  })
}

resource "aws_cloudwatch_event_target" "ecs_events_to_log" {
  rule      = aws_cloudwatch_event_rule.ecs_events_to_log.name
  arn       = aws_cloudwatch_log_group.ecs_events.arn
  target_id = "SendToCloudWatchLogs"

  # role_arn = aws_iam_role.eventbridge_cloudwatch.arn

  # target_json = jsonencode({
  #   MessageTemplate = "ECS Event: $$.detail-type | $$.detail"
  # })

}

resource "aws_ecs_task_definition" "alloy_ecsevents" {
  family                   = "${var.service_namespace}-alloy-ecsevents-task-def-${var.environment_id}"
  memory                   = "512"
  cpu                      = "256"
  execution_role_arn       = aws_iam_role.task_execution.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  volume {
    name = "alloy-ecsevents-config"
  }

  container_definitions = jsonencode([
    // Container that writes the Alloy configuration to a file
    {
      name      = "config-writer",
      essential = false,
      image     = "busybox:latest",
      memory    = 256,
      command = [
        "sh", "-c",
        "echo \"${replace(file("${path.module}/templates/config_ecsevents.alloy"), "\"", "\\\"")}\" > /etc/alloy/config.alloy"
      ],
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_events.name,
          "awslogs-region"        = data.aws_region.current.id,
          "awslogs-stream-prefix" = "config-writer"
        }
      },
      mountPoints = [
        {
          sourceVolume  = "alloy-ecsevents-config",
          containerPath = "/etc/alloy"
        }
      ]
    },
    {
      name      = "alloy-ecsevents"
      image     = "docker.io/grafana/alloy:latest"
      essential = true
      command = [
        "run",
        "--stability.level=experimental",
        "/etc/alloy/config.alloy",
      ]

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
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_events.name
          "awslogs-region"        = data.aws_region.current.id,
          "awslogs-stream-prefix" = "alloy"
        }
      }

      environment = [
        {
          name  = "LOG_GROUP_NAME",
          value = aws_cloudwatch_log_group.ecs_events.name
        },
        {
          name  = "LOKI_ENDPOINT",
          value = var.loki_endpoint_with_auth
        },
        {
          name  = "PROMETHEUS_REMOTE_WRITE_URL"
          value = var.prometheus_remote_write_url
        },
        {
          name  = "PROMETHEUS_USERNAME"
          value = var.prometheus_username
        },
        {
          name  = "PROMETHEUS_PASSWORD"
          value = var.grafana_cloud_access_policy_token
        }

        # {
        #   name  = "GRAFANA_CLOUD_LOGS_USERNAME"
        #   value = var.grafana_cloud_logs_username
        # }
      ],

      mountPoints = [
        {
          sourceVolume  = "alloy-ecsevents-config",
          containerPath = "/etc/alloy"
        }
      ]
    },
    {
      name      = "ecs-exporter"
      image     = "quay.io/prometheuscommunity/ecs-exporter:latest"
      essential = false
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_events.name,
          "awslogs-region"        = data.aws_region.current.id,
          "awslogs-stream-prefix" = "ecs-exporter"
        }
      },
    },
  ])
}

resource "aws_ecs_service" "alloy_ecsevents" {
  name            = "${var.service_namespace}-alloy-ecsevents"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.alloy_ecsevents.arn
  desired_count   = 2 # Simulate multiple instances of this app
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [data.aws_subnet.default.id]
    security_groups  = [data.aws_security_group.default.id]
    assign_public_ip = true
  }

  tags = {
    Name        = "${var.service_namespace}-alloy-ecsevents"
    Environment = var.environment_id
    Namespace   = var.service_namespace
  }

}
