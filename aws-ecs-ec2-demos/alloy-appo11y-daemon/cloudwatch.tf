resource "aws_cloudwatch_log_group" "alloy_logs" {
  name              = "/ecs/alloy-daemon-${var.environment_id}"
  retention_in_days = 7

  tags = {
    Name = "alloy-daemon-logs-${var.environment_id}"
  }
}