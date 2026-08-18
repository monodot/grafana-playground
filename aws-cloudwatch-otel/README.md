# AWS CloudWatch: shipping test logs

Example of how to ship test and query OpenTelemetry logs in AWS CloudWatch.

## Set up

Create the log group and stream:

```shell
aws logs create-log-group --log-group-name /otel/test-logs --region us-east-1

aws logs create-log-stream \
  --log-group-name /otel/test-logs \
  --log-stream-name telemetrygen-stream \
  --region us-east-1
  
aws logs create-log-stream \
  --log-group-name /otel/test-logs \
  --log-stream-name telemetrygen-stream-otlp \
  --region us-east-1
```

```shell
eval "$(aws configure export-credentials --profile <MYPROFILE> --format env)"
docker compose up
```

Then find the logs:

```shell
aws logs tail /otel/test-logs --since 5m --format short --region us-east-1
```

## What it produces

This produces log lines like this which shows how logs differ between the CloudWatch and OTLP exporters:

```text
# via Cloudwatch exporter
2026-08-18T18:04:54 {"resource":{"attributes":{"key1":"value1","service.name":"telemetrygen"},"schemaUrl":"https://opentelemetry.io/schemas/1.40.0"},"scope":{},"timeUnixNano":1787076294698458273,"observedTimeUnixNano":0,"severityNumber":9,"severityText":"Info","body":"the message","attributes":{"app":"server"},"traceId":"","spanId":""}

# via OTLP endpoint
2026-08-18T18:04:54 {"body":"the message","severity_number":9,"severity_text":"Info","attributes":{"app":"server"},"resource":{"key1":"value1","service.name":"telemetrygen"}}
```

## Tear down

```shell
docker compose down
```

Delete the CloudWatch log streams and groups:

```shell
aws logs delete-log-stream --log-group-name /otel/test-logs --log-stream-name telemetrygen-stream --region us-east-1
aws logs delete-log-stream --log-group-name /otel/test-logs --log-stream-name telemetrygen-stream-otlp --region us-east-1
aws logs delete-log-group --log-group-name /otel/test-logs --region us-east-1
```
