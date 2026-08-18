# Alloy behind Kong API Gateway

Shows how to send OTLP telemetry through Kong to Grafana Alloy, then from Alloy to the all-in-one Grafana OTEL LGTM stack. Kong provides a simple API-key
authentication boundary and a per-consumer rate limit.

```text
telemetrygen --OTLP/gRPC--> Kong :8000 --OTLP/gRPC--> Alloy --> otel-lgtm
                                         ^
                           OTLP/HTTP is also available at /v1/*
```

## Start the demo

```bash
docker compose up
```

Open Grafana at http://localhost:3000. The `telemetrygen-through-kong` service continuously emits traces, which should appear in Explore after a few seconds.

The public gateway endpoint is `localhost:8000`; Alloy's OTLP ports are not
published to the host. The generated client calls Kong over plaintext gRPC and
sends the `apikey: demo-key` metadata required by the `key-auth` plugin.

## Send OTLP through the gateway

The running `telemetrygen` service exercises the gRPC route. To generate an
extra short burst of traces:

```bash
docker compose run --rm telemetrygen traces \
  --otlp-endpoint=kong:8000 \
  --otlp-insecure \
  --otlp-header=apikey=\"demo-key\" \
  --service=manual-telemetrygen \
  --duration=10s
```

For OTLP/HTTP, use `http://localhost:8000` as the base endpoint, send the
standard `/v1/traces`, `/v1/metrics`, or `/v1/logs` path, and include the
`apikey: demo-key` header. For example:

```bash
telemetrygen traces --otlp-http --otlp-endpoint=localhost:8000 \
  --otlp-insecure --otlp-header=apikey=\"demo-key\" --duration=10s
```

Kong limits each authenticated consumer to 30 requests per minute. This is a
single-node `local` demonstration policy; use Kong's Redis policy and managed
credentials for a multi-node or production setup.

## Tear down

Stop the stack with:

```bash
docker compose down
```
