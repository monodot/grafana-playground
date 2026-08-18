# Alloy behind Apache APISIX API Gateway

Shows how to send OTLP telemetry through Apache APISIX to Grafana Alloy, then from Alloy to the all-in-one Grafana OTEL LGTM stack. APISIX provides API-key authentication and a per-consumer rate limit.

```text
telemetrygen --OTLP/gRPC--> APISIX :8000 --OTLP/gRPC--> Alloy --> otel-lgtm
                                           ^
                             OTLP/HTTP is also available at /v1/*
```

## Start the demo

```bash
docker compose up
```

Open Grafana at http://localhost:3000. The `telemetrygen-through-apisix` service continuously emits traces, which should appear in Explore after a few seconds.

The public gateway endpoint is `localhost:8000`; Alloy's OTLP ports are not
published to the host. The generated client calls APISIX over plaintext gRPC
and sends the `apikey: demo-key` metadata required by the `key-auth` plugin.

## Send OTLP through the gateway

The running `telemetrygen` service exercises the gRPC route. To generate an
extra short burst of traces:

```bash
docker compose run --rm telemetrygen traces \
  --otlp-endpoint=apisix:9080 \
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

APISIX limits each authenticated consumer to 30 requests per minute. This is a
single-node `local` demonstration policy; use a shared Redis policy or another
distributed rate-limit strategy for a multi-node or production deployment.

## Tear down

Stop the stack with:

```bash
docker compose down
```

## Demo and production risks

This APISIX example and the corresponding Kong example intentionally make the
same demo-oriented security trade-offs:

- `demo-key` is a checked-in, low-entropy credential. Replace it with
  per-client credentials sourced from a secret manager or identity provider.
- Gateway-to-client OTLP is plaintext. Terminate TLS (and normally require
  mTLS) at the gateway before exposing it beyond a trusted network.
- The rate limit is in-process and resets when its gateway container restarts;
  it is not shared by replicas. Use a distributed policy for horizontal scale.
- The examples use floating image tags for Alloy, LGTM, and telemetrygen.
  Pin and routinely update tested image digests in real deployments.

APISIX-specific: this demo uses standalone file-driven configuration, so
configuration is updated by changing `apisix/apisix.yaml`; it does not expose
the Admin API. Use a controlled configuration delivery process (or an
appropriately secured control plane) in production. The gRPC listener is
plaintext HTTP/2 (`h2c`), which is suitable only on trusted networks.

Kong-specific: the Kong example uses its single-node `local` rate-limit policy
and a database-less declarative configuration. A multi-node deployment needs a
shared rate-limit policy (such as Redis) and managed credentials; protect its
Admin API if it is enabled.
