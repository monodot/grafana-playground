# IAM role for EC2 instances (ECS container instances)
resource "aws_iam_role" "ecs_instance_role" {
  name = "alloy-daemon-ecs-instance-role-${var.environment_id}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "alloy-daemon-ecs-instance-role-${var.environment_id}"
  }
}

# Attach AWS managed policy for ECS EC2 role
resource "aws_iam_role_policy_attachment" "ecs_instance_role_policy" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

# Attach CloudWatch logs policy for ECS agent
resource "aws_iam_role_policy_attachment" "ecs_instance_cloudwatch" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

# Attach SSM policy for remote management via Session Manager
resource "aws_iam_role_policy_attachment" "ecs_instance_ssm" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance profile for EC2 instances
resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "alloy-daemon-ecs-instance-profile-${var.environment_id}"
  role = aws_iam_role.ecs_instance_role.name

  tags = {
    Name = "alloy-daemon-ecs-instance-profile-${var.environment_id}"
  }
}

# IAM role for ECS task execution (pulling images, writing logs)
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "alloy-daemon-task-execution-role-${var.environment_id}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "alloy-daemon-task-execution-role-${var.environment_id}"
  }
}

# Attach AWS managed policy for ECS task execution
resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Inline policy for task execution role to read SSM parameter (for secrets)
resource "aws_iam_role_policy" "ecs_task_execution_ssm_policy" {
  name = "alloy-daemon-execution-ssm-access-${var.environment_id}"
  role = aws_iam_role.ecs_task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameters",
          "ssm:GetParameter"
        ]
        Resource = aws_ssm_parameter.alloy_config.arn
      }
    ]
  })
}

# IAM role for ECS tasks (runtime permissions)
# Minimal permissions - Alloy doesn't need AWS API access
resource "aws_iam_role" "ecs_task_role" {
  name = "alloy-daemon-task-role-${var.environment_id}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "alloy-daemon-task-role-${var.environment_id}"
  }
}