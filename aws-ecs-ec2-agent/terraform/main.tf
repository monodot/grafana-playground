terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.10"
    }
  }
}

provider "aws" {
  region = "eu-west-1"
}

variable "loki_endpoint" {
  type    = string
  default = "https://logs-prod-008.grafana.net/loki/api/v1/push"
}

variable "prometheus_endpoint" {
  type    = string
  default = "https://prometheus-us-central1.grafana.net/api/prom/push"
}

variable "loki_username" {
  type    = string
  default = "123456"
}

variable "loki_password" {
  type    = string
  default = "aaaaaaaaaa"
}

variable "prometheus_username" {
  type    = string
  default = "123456"
}

variable "prometheus_password" {
  type    = string
  default = "aaaaaaaaaa"
}


output "cluster_node_1_public_ip" {
  value = aws_instance.cluster_node_1.public_ip
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet" "default" {
  vpc_id            = data.aws_vpc.default.id
  availability_zone = "eu-west-1b"
  default_for_az    = true
}

data "aws_security_group" "vpc_default" {
  name   = "default"
  vpc_id = data.aws_vpc.default.id
}

resource "aws_cloudwatch_log_group" "main" {
  name = "tomd-loki-ec2-cluster"

  tags = {
    purpose = "demo"
    owner   = "tomd"
  }
}

resource "aws_ecs_cluster" "main" {
  name = "tomd-loki-ec2-cluster"

  setting {
    name  = "containerInsights"
    value = "disabled"
  }

  tags = {
    purpose = "demo"
    owner   = "tomd"
  }
}

resource "aws_iam_role" "instance_role" {
  name = "lokiEcsEC2DemoInstanceRole"

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

  tags = {
    purpose = "demo"
    owner   = "tomd"
  }
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
  name = "lokiEcsEC2DemoInstanceRole-profile"
  role = aws_iam_role.instance_role.name
  tags = {
    purpose = "demo"
    owner   = "tomd"
  }
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
          path        = "/etc/agent/agent.yaml"
          permissions = "0644"
          owner       = "root"
          content = templatefile("${path.module}/templates/agent.yaml.tftpl", {
            loki_username       = "${var.loki_username}"
            loki_password       = "${var.loki_password}"
            loki_endpoint       = "${var.loki_endpoint}"
            prometheus_username = "${var.prometheus_username}"
            prometheus_password = "${var.prometheus_password}"
            prometheus_endpoint = "${var.prometheus_endpoint}"
          })
        },
        {
          path        = "/etc/ecs/ecs.config"
          permissions = "0644"
          owner       = "root"
          content     = "ECS_CLUSTER=tomd-loki-ec2-cluster"
        }
      ]
    })
  }

  # Rename the __HOSTNAME__ placeholders to the hostname of the ECS container instance
  # This will allow us to use it as a label for Loki
  part {
    filename = "set-hostname.sh"
    content_type = "text/x-shellscript"
    content = file("${path.module}/templates/set-hostname.sh")
  }
}

resource "aws_instance" "cluster_node_1" {
  ami                         = data.aws_ssm_parameter.ecs_default_ami.value
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.instance_profile.name
  subnet_id                   = data.aws_subnet.default.id
  vpc_security_group_ids      = [data.aws_security_group.vpc_default.id]
  #key_name                    = "${var.ssh_key}"

  user_data = data.cloudinit_config.cluster_node_1.rendered

  tags = {
    purpose = "demo"
    owner   = "tomd"
  }
}

resource "aws_ecs_task_definition" "demo" {
  family = "hello-world-demo"
  container_definitions = jsonencode([
    {
      name              = "sample-app"
      image             = "alpine:3.13"
      memoryReservation = 50
      command = [
        "/bin/sh -c \"while true; do sleep 15 ;echo hello_world; done\""
      ]
      entryPoint = [
        "sh",
        "-c"
      ]
      essential = true
    }
  ])

}

resource "aws_ecs_service" "demo" {
  name            = "tomd-loki-ec2-sleep"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.demo.arn
  desired_count   = 1
}



resource "aws_ecs_task_definition" "grafana_agent" {
  family = "grafana-agent-demo"
  container_definitions = jsonencode([
    {
      name              = "agent"
      image             = "grafana/agent:v0.35.4"
      memoryReservation = 50
      essential         = true
      command = [
        "-config.file=/etc/agent/agent.yaml",
        "-config.expand-env=true"
      ]
      mountPoints = [
        {
          sourceVolume  = "agent"
          containerPath = "/etc/agent"
          readOnly      = true
        },
        {
          sourceVolume  = "docker"
          containerPath = "/var/run/docker.sock"
        }
      ]
    }
  ])

  volume {
    name      = "agent"
    host_path = "/etc/agent"
  }
  volume {
    name      = "docker"
    host_path = "/var/run/docker.sock"
  }
}

resource "aws_ecs_service" "grafana_agent" {
  name                = "tomd-loki-ec2-grafana-agent"
  cluster             = aws_ecs_cluster.main.id
  task_definition     = aws_ecs_task_definition.grafana_agent.arn
  scheduling_strategy = "DAEMON"
}
