# Alloy: Drop unwanted OTLP logs attributes

Demonstrates how to use OTTL statements to filter and retain only specific log attributes when processing OTLP logs using Grafana Alloy.

## To run

```sh
cp .env.sample .env
```

Edit the .env file to add your backend details, then:

```sh
docker compose up
```

Alloy also writes some of the OTLP log records to stdout, so you can see them, e.g.:

```
[alloy]   | ts=2025-12-03T11:41:27.8139054Z level=info msg="ResourceLog #0\nResource SchemaURL: https://opentelemetry.io/schemas/1.6.1\nResource attributes:\n     -> service.name: Str(example-service)\n     -> service.version: Str(1.0.0)\n     -> telemetry.sdk.name: Str(beyla)\n     -> host.name: Str(03169ea476a8)\nScopeLogs #0\nScopeLogs SchemaURL: \nInstrumentationScope example-logger 1.0.0\nLogRecord #0\nObservedTimestamp: 2025-12-03 11:41:27.80596297 +0000 UTC\nTimestamp: 2025-12-03 11:41:27.80596297 +0000 UTC\nSeverityText: INFO\nSeverityNumber: Info(9)\nBody: Str(User login successful)\nAttributes:\n     -> user.id: Str(user123)\n     -> http.method: Str(POST)\n     -> http.status_code: Int(200)\n     -> custom.planet: Str(saturn)\n     -> custom.pet: Str(fido)\nTrace ID: 5b8aa5a2d2c872e8321cf37308d69df2\nSpan ID: 051581bf3cb55c13\nFlags: 0\n" component_path=/ component_id=otelcol.exporter.debug.console
```

## What it does

The example shows a complete Alloy pipeline that:

1. Receives OTLP logs via gRPC (port 4317) and HTTP (port 4318)
2. Detects resource attributes automatically (hostname, environment, etc.)
3. **Drops unwanted resource-level attributes** - Removes unnecessary _resource_ attributes like `process.pid`, `os.description`, and `k8s.pod.start_time` from logs, traces, and metrics
4. **Retains only specific log attributes** - Uses OTTL to keep only desired _attributes on log records_, dropping all others
5. Exports the processed logs to Grafana Cloud

## Key OTTL Statements

The critical attribute filtering happens in the `otelcol.processor.transform "drop_unneeded_resource_attributes"` component in `config.alloy`:

### Log Record Attributes (lines 85-92)

```alloy
log_statements {
    context = "log"
    statements = [
        "keep_keys(attributes, [\"user.id\", \"http.method\", \"http.status_code\", \"custom.planet\", \"custom.pet\"])",
    ]
}
```

This **`keep_keys`** OTTL statement retains only the specified attributes (`user.id`, `http.method`, `http.status_code`, `custom.planet`, `custom.pet`) on each log record and **drops all other attributes**, helping to reduce cardinality and control costs.

### Resource-Level Attributes (lines 70-83)

Additionally, unwanted resource-level attributes are removed using `delete_key` statements - these are the default recommended delete_key statements for use with Grafana Cloud:

```alloy
log_statements {
    context = "resource"
    statements = [
        "delete_key(attributes, \"k8s.pod.start_time\")",
        "delete_key(attributes, \"os.description\")",
        "delete_key(attributes, \"process.pid\")",
        // ... and more
    ]
}
```
