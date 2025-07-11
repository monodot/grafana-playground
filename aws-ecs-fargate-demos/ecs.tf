data "aws_vpc" "default" {
  default = true
}

data "aws_subnet" "default" {
  vpc_id            = data.aws_vpc.default.id
  availability_zone = "us-east-1b"
  default_for_az    = true
}

data "aws_security_group" "default" {
  name   = "default"
  vpc_id = data.aws_vpc.default.id
}

resource "aws_ecs_cluster" "main" {
  name = "ecs-fargate-${var.environment_id}"

  setting {
    name  = "containerInsights"
    value = "disabled"
  }

  tags = {
    purpose    = "demo"
    repository = "https://github.com/monodot/grafana-playground"
  }
}

resource "aws_iam_role" "task_execution" {
  name = "loki-ecs-task-execution-role-${var.environment_id}"

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
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
