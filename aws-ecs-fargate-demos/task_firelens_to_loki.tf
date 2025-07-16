resource "aws_cloudwatch_log_group" "firelens_to_loki" {
  name = "${var.service_namespace}-to-loki-${var.environment_id}"
}

resource "aws_ecs_task_definition" "firelens_to_loki" {
  family             = "${var.service_namespace}-to-loki-task-definition-${var.environment_id}"
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
      image             = var.fluent_bit_image
      name              = "log_router"
      memoryReservation = 50
      essential         = true
      user              = "0" # This MAY avoid Terraform from recreating the task definition each apply - see: https://github.com/hashicorp/terraform-provider-aws/issues/11526
      mountPoints       = []
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.firelens_to_loki.name
          "awslogs-region"        = "us-east-1"
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
        "/bin/sh -c \"while true; do sleep 15 ;echo from ecs-fargate-firelens-to-loki; done\""
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
          Labels     = "{service_name=\"ecs-fargate-firelens-to-loki\",service_namespace=\"${var.service_namespace}\"}"
          LineFormat = "key_value"
          RemoveKeys = "container_id,ecs_task_arn"
          Url        = var.loki_endpoint
        }
      }
    }
  ])

}

resource "aws_ecs_service" "firelens_to_loki" {
  name            = "${var.service_namespace}-to-loki"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.firelens_to_loki.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [data.aws_subnet.default.id]
    security_groups  = [data.aws_security_group.default.id]
    assign_public_ip = true
  }
}
