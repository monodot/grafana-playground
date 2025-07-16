# PHP Slim Framework demo on AWS App Runner

This repository contains a demonstration of how to deploy a PHP application with OpenTelemetry instrumentation to AWS App Runner and send telemetry data to Grafana Cloud.

## Overview

This demo showcases:

1. **PHP Slim Framework Application** - A simple PHP application ([index.php](app/public/index.php)) built with the [Slim Framework](https://www.slimframework.com/) that includes:
   - A `/rolldice` endpoint that simulates rolling a dice
   - A `/fetch` endpoint that demonstrates a network request
   - A `/users` endpoint that demonstrates database connectivity with MySQL
   - Automatic instrumentation with OpenTelemetry

2. **OpenTelemetry Integration** - The application is instrumented to send:
   - Traces - Track request flows and performance
   - Logs - Application logs sent via OTLP
   - (Metrics are disabled in this demo)

3. **Local Development with Grafana Alloy** ([config.alloy](alloy/config.alloy)) - Uses Grafana Alloy as a local collector to:
   - Process telemetry data before forwarding to Grafana Cloud
   - Demonstrate a local development workflow with full observability

4. **AWS App Runner Deployment** - Terraform configuration to deploy the application to AWS App Runner:
   - Creates an ECR repository for the container image
   - Sets up the App Runner service with proper configuration
   - Configures direct OTLP export to Grafana Cloud

## Key Features

- **Zero-code instrumentation** for PHP using OpenTelemetry auto-instrumentation
- **Database connectivity** with MySQL for demonstrating database traces
- **Containerized deployment** using Docker/Podman
- **Infrastructure as Code** with Terraform for AWS resources
- **Serverless deployment** with AWS App Runner for simplified operations

## To run locally

First create an `.env` file in the repo root directory with the following content:

```
GRAFANA_CLOUD_OTLP_ENDPOINT="https://otlp-gateway-..../otlp"
GRAFANA_CLOUD_INSTANCE_ID="123456"
GRAFANA_CLOUD_API_KEY="glc_eyJvI...=="
```

Then:

```shell
podman-compose up --build
docker-compose up --build  # If you prefer Docker

curl localhost:8080/rolldice
curl localhost:8080/fetch

podman-compose down
```

## Install more packages

If you add more functionality, you might need to add the relevant OpenTelemetry automatic instrumentation packages. As per [the upstream docs](https://opentelemetry.io/docs/zero-code/php/):

> Automatic instrumentation is available for a number of commonly used PHP libraries. For the full list, see instrumentation libraries on packagist.

Check the package you need at https://packagist.org/packages/open-telemetry/ and then add it:

```
podman run --rm -it -v $(pwd):/app composer require <package_name>
```

## Deploy to AWS with Terraform

Finally, you can deploy this application to AWS App Runner using Terraform. Make sure you have the AWS CLI configured and authenticated with your AWS account.

```shell
aws sso login --sso-session <sso_session_name>  # or however you authenticate with AWS
export AWS_PROFILE=<your_aws_profile>  # Set your AWS profile if needed

terraform -chdir=terraform init
terraform -chdir=terraform apply -target=aws_ecr_repository.this

export IMAGE_URI=$(terraform -chdir=terraform output -raw image_repository_url)
export IMAGE_REGISTRY=$(echo $IMAGE_URI | cut -d'/' -f1)

podman build -t $IMAGE_URI:latest app/

aws ecr get-login-password --region us-east-1 | podman login --username AWS --password-stdin $IMAGE_REGISTRY

podman push $IMAGE_URI:latest

# Apply the remaining resources after the image has been pushed
terraform -chdir=terraform apply
```

## Architecture

In **Local Development**, the architecture consists of:

- PHP application container
- MySQL database container
- Grafana Alloy container for telemetry collection
- Docker Compose for local orchestration

In **AWS Deployment**, the architecture consists of:

- ECR Repository for the application image
- App Runner service running the containerized application
- Direct OTLP export to Grafana Cloud
