# OpenTelemetry Collector: Convert OTLP Delta/Cumulative Metrics

Demonstrates how to convert the temporality type of metrics from delta to cumulative, in order to support Prometheus-based metrics backends, like Grafana Cloud.

An [Alloy-based example is also available in this repo](../alloy-metrics-delta-cumulative-convert).

This demo:

- exports a set of standard metrics and 1 custom metric (`dice.rolls.total`)
- uses `OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE` on the demo app to enforce a temporality type of `delta`
- uses the `deltatocumulative` processor in OpenTelemetry Collector to convert that delta temporality to _cumulative_
- ships the metric(s) to Grafana Cloud

## Run the app

Bring up the Compose configuration:

```sh
docker compose up
```

Then, go to http://localhost:8081/rolldice/ in your browser, or send a test request to the app:

```shell
curl localhost:8081/rolldice
```

### What does the temporality error look like?

Without the `deltatocumulative` processor, you would see something like this error in the otelcol logs:

> [otelcol] | 2025-12-08T14:01:08.793Z    error   internal/queue_sender.go:49     Exporting failed. Dropping data.        {"resource": {"service.instance.id": "9400b763-0c96-42cc-bf94-283ef9067d9a", "service.name": "otelcol-contrib", "service.version": "0.141.0"}, "otelcol.component.id": "otlphttp/grafana_cloud", "otelcol.component.kind": "exporter", "otelcol.signal": "metrics", "error": "not retryable error: Permanent error: rpc error: code = InvalidArgument desc = error exporting items, request to https://otlp-gateway-prod-gb-south-0.grafana.net/otlp/v1/metrics responded with HTTP Status Code 400, Message=otlp parse error: invalid temporality and type combination for metric \"dice.rolls\"; invalid temporality and type combination for metric \"http.server.request.body.size\"; invalid temporality and type combination for metric \"http.server.response.body.size\"; invalid temporality and type combination for metric \"http.server.request.duration\", Details=[]", "dropped_items": 8}

But with the `deltatocumulative` processor installed in the telemetry pipeline, this error should no longer appear.
