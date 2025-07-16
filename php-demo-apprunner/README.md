# PHP Demo on AWS App Runner

This directory contains an example PHP application instrumented with OpenTelemetry and deployed on AWS App Runner. The application sends telemetry data to Grafana Cloud using the OpenTelemetry Protocol (OTLP).

To deploy:

```shell
cd terraform

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
