terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}


# Data source to get current user - this is just to create a unique environment for you
# don't use this in a real environment, because you'll get inconsistent results
data "external" "whoami" {
  program = ["sh", "-c", "echo '{\"user\": \"'$(whoami)'\"}'"]
}

locals {
  common_tags = {
    purpose = "demo"
    expires = "2024-12-31"
    owner   = data.external.whoami.result.user
  }
  cluster_name = "${data.external.whoami.result.user}-loki-ec2-cluster"
}


data "aws_vpc" "default" {
  default = true
}

data "aws_subnet" "default" {
  vpc_id            = data.aws_vpc.default.id
  availability_zone = "us-west-2a"
  default_for_az    = true
}

resource "aws_cloudwatch_log_group" "main" {
  name = local.cluster_name

  tags = local.common_tags
}

resource "aws_ecs_cluster" "main" {
  name = local.cluster_name

  setting {
    name  = "containerInsights"
    value = "disabled"
  }

  tags = local.common_tags
}

resource "aws_iam_role" "instance_role" {
  name = "${data.external.whoami.result.user}-lokiEcsEC2AlloyDemoInstanceRole"

  # Allows tasks to assume an IAM role.
  # Allow EC2 instance to be managed using Session Manager.
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

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "instance_role_cloudwatch" {
  role       = aws_iam_role.instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

resource "aws_iam_role_policy_attachment" "instance_role_ecs" {
  role       = aws_iam_role.instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

# Allows us to manage these EC2 instances using AWS Session Manager
resource "aws_iam_role_policy_attachment" "instance_role_ssm" {
  role       = aws_iam_role.instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = "${data.external.whoami.result.user}-lokiEcsEC2AlloyDemoInstanceRole-profile"
  role = aws_iam_role.instance_role.name
  tags = local.common_tags
}


# Gets the AMI for the latest "recommended" Amazon Linux 2 optimised for ECS
data "aws_ssm_parameter" "ecs_default_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

data "cloudinit_config" "cluster_node_1" {
  gzip          = false
  base64_encode = false

  part {
    filename     = "init.yml"
    content_type = "text/cloud-config"
    content = jsonencode({
      write_files = [
        {
          path        = "/etc/alloy/config.alloy"
          permissions = "0644"
          owner       = "root"
          content = templatefile("${path.module}/templates/config.alloy.tftpl", {
            cluster_name = local.cluster_name
          })
        },
        {
          path        = "/etc/ecs/ecs.config"
          permissions = "0644"
          owner       = "root"
          content     = "ECS_CLUSTER=${local.cluster_name}"
        }
      ]
    })
  }

  # Replace the __HOSTNAME__ placeholders with the hostname of the ECS container instance
  # This will allow us to set it as a label for Loki
  part {
    filename     = "set-hostname.sh"
    content_type = "text/x-shellscript"
    content      = file("${path.module}/templates/set-hostname.sh")
  }
}

# Create a security group
resource "aws_security_group" "nodes" {
  name        = "${local.cluster_name}-sg"
  description = "Security group for ECS nodes"

  ingress {
    description = "SSH from EC2 Instance Connect range"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["18.237.140.160/29"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "cluster_node_1" {
  ami                         = data.aws_ssm_parameter.ecs_default_ami.value
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.instance_profile.name
  subnet_id                   = data.aws_subnet.default.id
  vpc_security_group_ids      = [aws_security_group.nodes.id]

  user_data = data.cloudinit_config.cluster_node_1.rendered

  tags = merge(
    {
      Name = "${local.cluster_name}-1"
    },
    local.common_tags
  )
}

