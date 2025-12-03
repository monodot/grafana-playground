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
