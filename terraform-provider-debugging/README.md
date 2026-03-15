# Terraform/OpenTofu: Provider debugging with traces and profiles

Adds OpenTelemetry instrumentation, shipping signals to Grafana, to observe an OpenTofu run.

## Getting started

First allow otel-ebpf-profiler to scrape profiling data:

```shell
sudo sysctl -w kernel.kptr_restrict=0
```

Then:

```shell
sudo podman-compose up
```

And then apply the Terraform configuration:

```shell
cd terraform

export OTEL_TRACES_EXPORTER=otlp
export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318
export OTEL_EXPORTER_OTLP_INSECURE=true

tofu init

tofu apply
```
