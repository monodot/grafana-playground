# Get the latest ECS-optimized Amazon Linux 2 AMI
data "aws_ssm_parameter" "ecs_optimized_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

# EC2 instances running ECS agent
resource "aws_instance" "ecs_node" {
  count = var.instance_count

  ami                         = data.aws_ssm_parameter.ecs_optimized_ami.value
  instance_type               = "t3.micro"
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ecs_instance_profile.name
  subnet_id                   = data.aws_subnet.default.id
  vpc_security_group_ids      = [aws_security_group.ecs_cluster.id]

  user_data = <<-EOF
    #!/bin/bash
    echo "ECS_CLUSTER=${aws_ecs_cluster.workshop.name}" >> /etc/ecs/ecs.config
  EOF

  tags = {
    Name = "alloy-daemon-ecs-node-${count.index + 1}-${var.environment_id}"
  }
}