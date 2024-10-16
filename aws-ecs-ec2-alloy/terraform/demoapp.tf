resource "aws_ecs_task_definition" "demoapp" {
  family = "${data.external.whoami.result.user}-demoapp"
  container_definitions = jsonencode([
    {
      name              = "demo-app"
      image             = "docker.io/mingrammer/flog:latest"
      memoryReservation = 50
      command = [ "--format", "json", "--delay", "1s", "--loop" ]
      essential = true
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.main.name
          "awslogs-region"        = "us-west-2"
          "awslogs-stream-prefix" = "ecs-demo"
        }
      }
    }
  ])

}

resource "aws_ecs_service" "demoapp" {
  name            = "${data.external.whoami.result.user}-demoapp"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.demoapp.arn
  desired_count   = 1
}
