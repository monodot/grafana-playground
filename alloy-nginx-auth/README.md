# Alloy: Protecting OTLP endpoints with nginx header authentication

Demonstrates how to protect Grafana Alloy's OTLP endpoints using nginx as a reverse proxy with custom header authentication supporting multiple client tokens.

## Architecture

```
Client → nginx (checks X-Example-Key header) → Alloy → otel-lgtm (Grafana/Loki/Tempo/Mimir)
```

nginx validates incoming requests against a list of valid tokens stored in `nginx/tokens.map`. Each token is associated with a client name. Valid requests are forwarded to Alloy with an additional `X-Client-Name` header containing the client identifier. Requests with invalid or missing tokens receive a 401 Unauthorized response.

The following endpoints are protected:
- **Port 4317**: OTLP gRPC (traces, metrics, logs)
- **Port 4318**: OTLP HTTP (traces, metrics, logs)
- **Port 9090**: Prometheus remote_write

## Token Management

Tokens are defined in `nginx/tokens.map` with the format:

```nginx
"token-value"  client-name;
```

The default configuration includes three example tokens:
- `token-client-a-12345` for client-a
- `token-client-b-67890` for client-b
- `token-client-c-abcde` for client-c

## How to run

```shell
podman-compose up
```

Access Grafana at http://localhost:3000

The stack includes two demo clients:
- **client-a**: Continuously generates traces using `telemetrygen`, authenticating with `token-client-a-12345` via the `OTEL_EXPORTER_OTLP_HEADERS` environment variable. You should see traces appearing in Grafana from the service `opentelemetry-example-service`.
- **client-b**: Runs Prometheus that scrapes its own metrics and remote_writes them to the protected nginx endpoint, authenticating with `token-client-b-67890` via the `X-Example-Key` header. You should see Prometheus metrics appearing in Grafana with the `client: client-b` label.

## Testing

### Manual Testing with curl

Test with a valid token from client-a (should succeed):

```shell
curl -v -X POST http://localhost:4318/v1/traces \
  -H "Content-Type: application/json" \
  -H "X-Example-Key: token-client-a-12345" \
  -d '{
    "resourceSpans": [{
      "resource": {
        "attributes": [{
          "key": "service.name",
          "value": {"stringValue": "test-service"}
        }]
      },
      "scopeSpans": [{
        "spans": [{
          "traceId": "5b8efff798038103d269b633813fc60c",
          "spanId": "eee19b7ec3c1b174",
          "name": "test-span",
          "startTimeUnixNano": "1544712660000000000",
          "endTimeUnixNano": "1544712661000000000",
          "kind": 1
        }]
      }]
    }]
  }'
```

Test without the header (should fail with 401):

```shell
curl -v -X POST http://localhost:4318/v1/traces \
  -H "Content-Type: application/json" \
  -d '{
    "resourceSpans": [{
      "resource": {
        "attributes": [{
          "key": "service.name",
          "value": {"stringValue": "test-service"}
        }]
      },
      "scopeSpans": [{
        "spans": [{
          "traceId": "5b8efff798038103d269b633813fc60c",
          "spanId": "eee19b7ec3c1b174",
          "name": "test-span",
          "startTimeUnixNano": "1544712660000000000",
          "endTimeUnixNano": "1544712661000000000",
          "kind": 1
        }]
      }]
    }]
  }'
```

Test with a valid token from client-b (should succeed):

```shell
curl -v -X POST http://localhost:4318/v1/traces \
  -H "Content-Type: application/json" \
  -H "X-Example-Key: token-client-b-67890" \
  -d '{
    "resourceSpans": [{
      "resource": {
        "attributes": [{
          "key": "service.name",
          "value": {"stringValue": "test-service"}
        }]
      },
      "scopeSpans": [{
        "spans": [{
          "traceId": "5b8efff798038103d269b633813fc60c",
          "spanId": "eee19b7ec3c1b174",
          "name": "test-span",
          "startTimeUnixNano": "1544712660000000000",
          "endTimeUnixNano": "1544712661000000000",
          "kind": 1
        }]
      }]
    }]
  }'
```

Test with an incorrect token value (should fail with 401):

```shell
curl -v -X POST http://localhost:4318/v1/traces \
  -H "Content-Type: application/json" \
  -H "X-Example-Key: wrong-key" \
  -d '{
    "resourceSpans": [{
      "resource": {
        "attributes": [{
          "key": "service.name",
          "value": {"stringValue": "test-service"}
        }]
      },
      "scopeSpans": [{
        "spans": [{
          "traceId": "5b8efff798038103d269b633813fc60c",
          "spanId": "eee19b7ec3c1b174",
          "name": "test-span",
          "startTimeUnixNano": "1544712660000000000",
          "endTimeUnixNano": "1544712661000000000",
          "kind": 1
        }]
      }]
    }]
  }'
```

## Configuration

### Adding or Modifying Tokens

To add, remove, or modify tokens, edit `nginx/tokens.map`:

```nginx
"your-token-value"  your-client-name;
```

After modifying the file, reload nginx to apply changes:

```shell
podman-compose exec nginx nginx -s reload
```

### Configuring Applications

To configure your application to authenticate with the protected OTLP endpoint, set the `OTEL_EXPORTER_OTLP_HEADERS` environment variable with your client's token:

```shell
OTEL_EXPORTER_OTLP_HEADERS="X-Example-Key=token-client-b-67890"
OTEL_EXPORTER_OTLP_ENDPOINT="http://nginx:4318"
```

This is demonstrated in the `client-a` service in compose.yaml, which uses telemetrygen to continuously send traces.

### Testing Prometheus Remote Write

The `client-b` service automatically sends Prometheus metrics via remote_write. To manually test sending metrics via Prometheus remote_write with a valid token:

```shell
curl -v -X POST http://localhost:9090/api/v1/metrics/write \
  -H "Content-Type: application/x-protobuf" \
  -H "X-Example-Key: token-client-b-67890" \
  -H "X-Prometheus-Remote-Write-Version: 0.1.0" \
  --data-binary @- <<EOF
# This would normally be protobuf data
# For a real test, use a tool like promtool or configure Prometheus agent mode
EOF
```

To configure Prometheus to use the protected remote_write endpoint, add to your `prometheus.yml`:

```yaml
remote_write:
  - url: http://nginx:9090/api/v1/metrics/write
    headers:
      X-Example-Key: token-client-b-67890
```
