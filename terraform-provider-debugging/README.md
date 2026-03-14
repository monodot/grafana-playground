# Terraform/OpenTofu: Provider debugging with traces and profiles

Uses OpenTelemetry and Grafana to observe an OpenTofu run.

```shell
podman-compose up
```

And then apply the Terraform configuration:

```shell
cd terraform

export OTEL_TRACES_EXPORTER=otlp
export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317
export OTEL_EXPORTER_OTLP_INSECURE=true

tofu init

tofu apply
```
