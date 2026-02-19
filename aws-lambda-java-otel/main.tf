terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

data "external" "whoami" {
  program = ["sh", "-c", "echo '{\"user\": \"'$(whoami)'\"}'"]
}

locals {
  common_tags = {
    purpose = "demo"
    owner   = data.external.whoami.result.user
    repo    = "https://github.com/monodot/grafana-playground"
  }
}
