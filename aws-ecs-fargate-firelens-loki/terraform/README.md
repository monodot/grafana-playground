# AWS: Send logs from an ECS Fargate Task to Grafana Cloud Logs using AWS Firelens log router

This uses:

- AWS
- ECS with Fargate
- Firelens (which is a container that runs alongside your application container and sends logs to a destination of your choice)

To run this, first set the variable `loki_endpoint` to your Grafana Cloud Logs endpoint (with username, API key and hostname). Then:

```
terraform init

terraform apply
```
