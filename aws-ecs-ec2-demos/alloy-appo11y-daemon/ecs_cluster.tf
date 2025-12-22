resource "aws_ecs_cluster" "workshop" {
  name = "alloy-daemon-cluster-${var.environment_id}"

  setting {
    name  = "containerInsights"
    value = "disabled"
  }

  tags = {
    Name = "alloy-daemon-cluster-${var.environment_id}"
  }
}

