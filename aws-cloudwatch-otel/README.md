# Grafana Cloud and AWS CloudWatch: shipping test OTLP logs

Example of how to ship test OpenTelemetry logs to both Grafana Cloud and AWS
CloudWatch's native OTLP endpoint.

## Set up

Create the CloudWatch log group and stream:

```shell
aws logs create-log-group --log-group-name /otel/test-logs --region us-east-1

aws logs create-log-stream \
  --log-group-name /otel/test-logs \
  --log-stream-name telemetrygen-stream-otlp \
  --region us-east-1
```

In Grafana Cloud, open the stack's **OpenTelemetry** tile and copy its OTLP
endpoint, instance ID, and access-policy token. Export them without committing
them to the repository:

```shell
eval "$(aws configure export-credentials --profile <MYPROFILE> --format env)"
export GRAFANA_CLOUD_OTLP_ENDPOINT="https://otlp-gateway-<region>.grafana.net/otlp"
export GRAFANA_CLOUD_OTLP_USERNAME="<OTLP instance ID>"
export GRAFANA_CLOUD_OTLP_PASSWORD="<access-policy token>"
docker compose up
```

Each generated log is sent to both backends. Find the CloudWatch copy with:

```shell
aws logs tail /otel/test-logs --since 5m --format short --region us-east-1
```

## What it produces

CloudWatch stores the native OTLP representation of each log record:

```text
2026-08-18T18:04:54 {"resource":{"attributes":{"key1":"value1","service.name":"telemetrygen"},"schemaUrl":"https://opentelemetry.io/schemas/1.40.0"},"scope":{},"timeUnixNano":1787076294698458273,"observedTimeUnixNano":0,"severityNumber":9,"severityText":"Info","body":"the message","attributes":{"app":"server"},"traceId":"","spanId":""}
```

## Tear down

```shell
docker compose down
```

Delete the CloudWatch log streams and groups:

```shell
aws logs delete-log-stream --log-group-name /otel/test-logs --log-stream-name telemetrygen-stream-otlp --region us-east-1
aws logs delete-log-group --log-group-name /otel/test-logs --region us-east-1
```

## Sample volume data

With the included `telemetrygen` application which writes the log `"the message"` (length: 11 characters) every 1 second:

- **Loki's** `bytes_over_time` records 660 bytes every 1 minute, which is equivalent to 11 bytes per second (excluding structured metadata):

    ```
    gcx logs metrics 'sum(bytes_over_time({service_name="telemetrygen"}[30m])) by (detected_level)' \
        -d 'grafanacloud-logs' --context tomdonohue \
        --from '2026-08-18T19:20:00Z' --to '2026-08-18T19:20:00Z'
    # returns 19800 over 30 minutes
    ```

- **CloudWatch's** `IncomingBytes` metric records 727604 bytes over 30 minutes:

    ```
    aws cloudwatch get-metric-statistics \
        --namespace AWS/Logs --metric-name IncomingBytes \
        --dimensions Name=LogGroupName,Value=/otel/test-logs \
        --start-time 2026-08-18T18:50:00Z --end-time 2026-08-18T19:20:00Z \
        --statistics Sum --period 3600 --region us-east-1
    # {
    #   "Label": "IncomingBytes",
    #   "Datapoints": [
    #     {
    #       "Timestamp": "2026-08-18T18:50:00+00:00",
    #       "Sum": 727604.0,
    #       "Unit": "Bytes"
    #     }
    #  ]
    # }
    ```
