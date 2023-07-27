provider "aws" {
  region = "eu-west-1"
}

variable "loki_endpoint" {
  type    = string
  default = "https://123456:aaaaaaaaaa@logs-prod-008.grafana.net/loki/api/v1/push"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet" "default" {
  vpc_id            = data.aws_vpc.default.id
  availability_zone = "eu-west-1b"
  default_for_az    = true
}

data "aws_security_group" "default" {
  name   = "default"
  vpc_id = data.aws_vpc.default.id
}

resource "aws_ecs_cluster" "main" {
  name = "tomd-loki-firelens-cluster"

  setting {
    name  = "containerInsights"
    value = "disabled"
  }

  tags = {
    purpose = "demo"
    owner   = "tomd"
  }
}

resource "aws_iam_role" "task_execution" {
  name = "lokiEcsTaskExecutionRole"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    purpose = "demo"
    owner   = "tomd"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_cloudwatch_log_group" "example" {
  name = "loki-ecs-fargate-firelens"

  tags = {
    purpose = "demo"
    owner   = "tomd"
  }
}


resource "aws_ecs_task_definition" "hello_world_loki" {
  family             = "loki-fargate-task-definition"
  memory             = "512"
  cpu                = "256"
  execution_role_arn = aws_iam_role.task_execution.arn
  network_mode       = "awsvpc"
  requires_compatibilities = [
    "FARGATE"
  ]
  container_definitions = jsonencode([
    {
      essential         = true
      image             = "grafana/fluent-bit-plugin-loki:2.8.1-amd64"
      name              = "log_router"
      memoryReservation = 50
      essential         = true
      mountPoints       = []
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.example.name
          "awslogs-region"        = "eu-west-1"
          "awslogs-stream-prefix" = "firelens"
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
        "/bin/sh -c \"while true; do sleep 15 ;echo hello_world; done\""
      ]
      entryPoint = [
        "sh",
        "-c"
      ]
      image     = "alpine:3.13"
      essential = true
      logConfiguration = {
        logDriver = "awsfirelens"
        options = {
          Name       = "grafana-loki"
          LabelKeys  = "container_name,ecs_task_definition,source,ecs_cluster"
          Labels     = "{job=\"firelens\",fun=\"lots\"}"
          LineFormat = "key_value"
          RemoveKeys = "container_id,ecs_task_arn"
          Url        = var.loki_endpoint
        }
      }
    }
  ])

}

resource "aws_ecs_service" "hello_world_loki" {
  name            = "tomd-firelens-loki-fargate"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.hello_world_loki.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [data.aws_subnet.default.id]
    security_groups  = [data.aws_security_group.default.id]
    assign_public_ip = true
  }
}