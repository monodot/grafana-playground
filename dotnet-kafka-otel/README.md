# .NET Core 10: Kafka consumer example

Example .NET Core application which consumes messages from a Kafka topic, instrumented with OpenTelemetry.

## Basic steps followed

Following: https://grafana.com/docs/opentelemetry/instrument/grafana-dotnet/

1. Add OpenTelemetry packages:

    ```sh
    dotnet add package Grafana.OpenTelemetry
    
    dotnet add package OpenTelemetry.Exporter.Console
    ```

1. Add bootstrapping code to `Program.cs`.

1. Run with:

    ```sh
    OTEL_RESOURCE_ATTRIBUTES="service.name=myapp,service.namespace=apps,deployment.environment=local" \
    OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317 \
    OTEL_EXPORTER_OTLP_PROTOCOL="http/protobuf" \
    dotnet run
    ```

1. You should see some output in the console, like:
    
    ```sh
    tdonohue@harold:~/repos/grafana-playground/dotnet-kafka-otel$   OTEL_RESOURCE_ATTRIBUTES="service.name=myapp,service.namespace=apps,deployment.environment=local" \
    >   OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317 \
    >   OTEL_EXPORTER_OTLP_PROTOCOL="http/protobuf" \
    >   dotnet run
    Hello, World!
    Resource associated with Metrics:
    service.name: dotnet-kafka-otel
    service.version: 1.0.0.0
    service.instance.id: 0c23ab47-aff7-4b82-b8b5-62f2dc562c4c
    telemetry.distro.name: grafana-opentelemetry-dotnet
    telemetry.distro.version: 1.3.0
    deployment.environment: production
    process.runtime.description: .NET 10.0.0
    process.runtime.name: .NET
    process.runtime.version: 10.0.0
    process.owner: tdonohue
    process.pid: 4089784
    host.name: harold
    host.id: b12657d0111843379fd4c6885223255e
    service.namespace: apps
    telemetry.sdk.name: opentelemetry
    telemetry.sdk.language: dotnet
    telemetry.sdk.version: 1.14.0
    ```
