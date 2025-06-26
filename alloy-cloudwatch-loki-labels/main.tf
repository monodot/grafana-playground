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
  region = "us-east-1"
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

# Data source to get current user - this is just to create a unique environment for you
# don't use this in a real environment, because you'll get inconsistent results
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

