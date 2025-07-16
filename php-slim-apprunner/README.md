# PHP Slim Framework demo on AWS App Runner

This directory contains an example PHP [Slim Framework](https://www.slimframework.com/) application instrumented with OpenTelemetry and deployed on AWS App Runner. The application sends telemetry data to Grafana Cloud using the OpenTelemetry Protocol (OTLP).

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

curl localhost:8080/rolldice
curl localhost:8080/fetch

podman-compose down
```

## Add more packages

You might need to add the relevant automatic instrumentation packages. As per [the upstream docs](https://opentelemetry.io/docs/zero-code/php/):

> Automatic instrumentation is available for a number of commonly used PHP libraries. For the full list, see instrumentation libraries on packagist.

Check the package you need at https://packagist.org/packages/open-telemetry/ and then add a package:

```
podman run --rm -it -v $(pwd):/app composer require <package_name>
```

## Deploy to AWS with Terraform

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
