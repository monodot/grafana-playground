# PHP: Demo from OpenTelemetry docs

This directory contains the demo app described in the upstream OpenTelemetry zero-code documentation.

It's packaged into a container and run with a Compose configuration.

Create an file called `.env`:

```
GRAFANA_CLOUD_OTLP_ENDPOINT="https://otlp-gateway-REGION.grafana.net/otlp"
GRAFANA_CLOUD_INSTANCE_ID="123456"
GRAFANA_CLOUD_API_KEY="glc_eyJvI...=="
```

Then run:

```
docker-compose up
```

