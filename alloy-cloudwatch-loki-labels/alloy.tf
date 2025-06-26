locals {
  alloy_config = file("${path.module}/templates/config.alloy")
}

data "aws_ssm_parameter" "latest_amazon_linux_2023_x86_64" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_iam_role" "alloy_ec2" {
  name = "alloy-ec2-demo-${data.external.whoami.result.user}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
      },
    ],
  })
}

resource "aws_iam_instance_profile" "grafana_alloy_profile" {
  name = "alloy-ec2-demo-${data.external.whoami.result.user}-profile"
  role = aws_iam_role.alloy_ec2.name
}


resource "aws_iam_policy" "cloudwatch_logs_read_policy" {
  name        = "alloy-cloudwatch-logs-read-policy-${data.external.whoami.result.user}"
  description = "Allows Grafana Alloy EC2 instances to read CloudWatch Logs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:FilterLogEvents",
          "logs:DescribeLogGroups", # Recommended for discovering log groups
          "logs:GetLogEvents"       # Recommended for retrieving individual log events
        ]
        Effect = "Allow"
        # IMPORTANT: For production, narrow down this resource to specific log groups if possible.
        # Example: "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/ec2/your-app-logs:*"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_ssm_access" {
  role       = aws_iam_role.alloy_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "alloy_ec2_cloudwatch_logs_access" {
  role       = aws_iam_role.alloy_ec2.name
  policy_arn = aws_iam_policy.cloudwatch_logs_read_policy.arn
}

resource "aws_security_group" "grafana_alloy_sg" {
  name        = "grafana-alloy-sg"
  description = "Security group for Grafana Alloy instances"

  # No ingress rules defined here for external access, so you can't SSH directly to this box.
  # Access is via AWS Systems Manager Session Manager.

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "grafana_alloy" {
  count                  = var.alloy_instance_count
  ami                    = data.aws_ssm_parameter.latest_amazon_linux_2023_x86_64.value
  instance_type          = var.alloy_instance_type
  iam_instance_profile   = aws_iam_instance_profile.grafana_alloy_profile.name
  vpc_security_group_ids = [aws_security_group.grafana_alloy_sg.id]

  tags = merge(
    {
      Name = "${data.external.whoami.result.user}-grafana-alloy-${count.index + 1}"
    },
    local.common_tags
  )

  user_data = templatefile("${path.module}/templates/user_data.sh.tftpl", {
    alloy_config  = local.alloy_config
    loki_endpoint = var.loki_endpoint
    loki_username = var.loki_username
    loki_password = var.grafana_cloud_api_key
    otlp_username = var.otlp_username
    otlp_endpoint = var.otlp_endpoint
  })

}

