# ── ECS Fargate OTel Collector (config 5) ────────────────────────────────────

resource "aws_ecs_cluster" "ecs_collector" {
  name = "${var.name_prefix}-ext-collector"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_log_group" "ecs_collector" {
  name              = "/ecs/${var.name_prefix}-ext-collector"
  retention_in_days = 7
  tags              = local.common_tags
}

# ── IAM — task execution role ─────────────────────────────────────────────────

resource "aws_iam_role" "ecs_collector_execution" {
  name = "${var.name_prefix}-ext-collector-exec"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "ecs_collector_execution_basic" {
  role       = aws_iam_role.ecs_collector_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ── IAM — task role ───────────────────────────────────────────────────────────
# The collector only needs network egress to Grafana Cloud.

resource "aws_iam_role" "ecs_collector_task" {
  name = "${var.name_prefix}-ext-collector-task"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })

  tags = local.common_tags
}

# ── Security Group ────────────────────────────────────────────────────────────

resource "aws_security_group" "ecs_collector_task" {
  name        = "${var.name_prefix}-ext-collector-task"
  description = "OTel Collector Fargate task - inbound OTLP from Lambda only"
  vpc_id      = aws_vpc.this.id

  ingress {
    description     = "OTLP HTTP from config_5 Lambda"
    from_port       = 4318
    to_port         = 4318
    protocol        = "tcp"
    security_groups = [aws_security_group.config_5_lambda.id]
  }

  ingress {
    description     = "OTLP gRPC from config_5 Lambda"
    from_port       = 4317
    to_port         = 4317
    protocol        = "tcp"
    security_groups = [aws_security_group.config_5_lambda.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

# ── Network Load Balancer ─────────────────────────────────────────────────────

resource "aws_lb" "ecs_collector" {
  name               = "${var.name_prefix}-ext-col"
  internal           = true
  load_balancer_type = "network"
  subnets            = aws_subnet.private[*].id
  tags               = local.common_tags
}

resource "aws_lb_target_group" "ecs_collector_otlp_http" {
  name        = "${var.name_prefix}-ext-otlp"
  port        = 4318
  protocol    = "TCP"
  vpc_id      = aws_vpc.this.id
  target_type = "ip"

  health_check {
    enabled             = true
    protocol            = "TCP"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
  }

  tags = local.common_tags
}

resource "aws_lb_listener" "ecs_collector_otlp_http" {
  load_balancer_arn = aws_lb.ecs_collector.arn
  port              = 4318
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_collector_otlp_http.arn
  }
}

# ── ECS Task Definition ───────────────────────────────────────────────────────

data "aws_region" "current" {}

resource "aws_ecs_task_definition" "ecs_collector" {
  family                   = "${var.name_prefix}-ext-collector"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_collector_execution.arn
  task_role_arn            = aws_iam_role.ecs_collector_task.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([{
    name      = "collector"
    image     = "docker.io/otel/opentelemetry-collector-contrib:0.147.0"
    essential = true
    command   = ["--config=env:OTEL_CONFIG"]

    environment = [
      { name = "OTEL_CONFIG",                   value = file("${path.module}/../collector-config/ecs-fargate.yaml") },
      { name = "GRAFANA_CLOUD_OTLP_ENDPOINT",   value = var.grafana_cloud_otlp_endpoint },
      { name = "GRAFANA_CLOUD_AUTH",             value = local.grafana_auth },
    ]

    portMappings = [
      { containerPort = 4318, hostPort = 4318, protocol = "tcp" },
      { containerPort = 4317, hostPort = 4317, protocol = "tcp" },
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.ecs_collector.name
        "awslogs-region"        = data.aws_region.current.name
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])

  tags = local.common_tags
}

# ── ECS Service ───────────────────────────────────────────────────────────────

resource "aws_ecs_service" "ecs_collector" {
  name            = "${var.name_prefix}-ext-collector"
  cluster         = aws_ecs_cluster.ecs_collector.id
  task_definition = aws_ecs_task_definition.ecs_collector.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_collector_task.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_collector_otlp_http.arn
    container_name   = "collector"
    container_port   = 4318
  }

  depends_on = [aws_lb_listener.ecs_collector_otlp_http]

  tags = local.common_tags
}