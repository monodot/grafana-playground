# Data sources for default VPC and subnet
data "aws_vpc" "default" {
  default = true
}

data "aws_subnet" "default" {
  vpc_id            = data.aws_vpc.default.id
  availability_zone = "us-east-1a"
  default_for_az    = true
}

# Security group for ECS cluster EC2 instances
resource "aws_security_group" "ecs_cluster" {
  name        = "alloy-daemon-ecs-cluster-${var.environment_id}"
  description = "Security group for Alloy daemon ECS cluster instances"
  vpc_id      = data.aws_vpc.default.id

  # Allow OTLP gRPC traffic only from within the same security group
  ingress {
    description     = "OTLP gRPC from ECS cluster"
    from_port       = 4317
    to_port         = 4317
    protocol        = "tcp"
    self            = true
  }

  # Allow OTLP HTTP traffic only from within the same security group
  ingress {
    description     = "OTLP HTTP from ECS cluster"
    from_port       = 4318
    to_port         = 4318
    protocol        = "tcp"
    self            = true
  }

  # Allow all outbound traffic (needed for pulling images, sending to Grafana Cloud)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alloy-daemon-ecs-cluster-sg-${var.environment_id}"
  }
}