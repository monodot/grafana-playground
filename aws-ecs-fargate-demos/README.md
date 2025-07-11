# AWS ECS Fargate demos

These demos show various ways of shipping telemetry from AWS ECS Fargate to the Grafana LGTM stack, or Grafana Cloud, using:

- AWS
- ECS with Fargate
- Firelens (which is a container that runs alongside your application container and sends logs to a destination of your choice)

This demo does some imporant things:

- Sets the `service_name` label to the Loki logs, which is essential for easy navigation in Grafana Drilldown Logs.

To run this, first set the variable `loki_endpoint` to your Grafana Cloud Logs endpoint (with username, API key and hostname). Then:

```
terraform init

terraform apply
```
