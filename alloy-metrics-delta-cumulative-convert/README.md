# Alloy: Convert OTLP Delta/Cumulative Metrics

Demonstrates how to convert the temporality type of metrics from delta to cumulative, in order to support Prometheus-based metrics backends, like Grafana Cloud.

This demo:

- exports a set of standard metrics and 1 custom metric (`dice.rolls.total`)
- uses `OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE` on the demo app to enforce a temporality type of `delta`
- uses the `otelcol.processor.deltatocumulative` component in Grafana Alloy to convert that delta temporality to _cumulative_
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

If you've not converted the temporality from delta to cumulative, you'll see logs like this in Alloy and Grafana Cloud:

> [alloy] | ts=2025-12-08T13:31:34.146517099Z level=error msg="Exporting failed. Dropping data." component_path=/ component_id=otelcol.exporter.otlphttp.grafana_cloud error="not retryable error: Permanent error: rpc error: code = InvalidArgument desc = error exporting items, request to https://otlp-gateway-prod-gb-south-0.grafana.net/otlp/v1/metrics responded with HTTP Status Code 400, Message=otlp parse error: invalid temporality and type combination for metric \"http.server.request.body.size\"; invalid temporality and type combination for metric \"http.server.response.body.size\"; invalid temporality and type combination for metric \"http.server.request.duration\"; invalid temporality and type combination for metric \"dice.rolls\", Details=[]" dropped_items=4
