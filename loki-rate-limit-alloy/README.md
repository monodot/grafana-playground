# loki-rate-limit-alloy

Shows how rate limiting works in Loki and Alloy. Sets an arbitrary rate limit in Loki. Then sends more than this in bursts, and observes how Loki and Alloy handle the rate limiting.

## Prerequisites

- Docker
- Docker Compose
- logcli (from the Grafana Loki distribution)

## How to run

```shell
podman-compose up
```

Then you can check that Loki is receiving all the app's logs:

```shell
logcli series '{}'
# should return:
# {demo="loki-rate-limit-alloy", filename="/var/log/shared/app.log", repo="monodot/grafana-playground"}

logcli query '{demo="loki-rate-limit-alloy"}'

logcli query --tail '{demo="loki-rate-limit-alloy"}'
```

### See rate limiting in action
Go to Grafana at http://localhost:3000 and check the "Loki rate limit demo" dashboard to see:

- Loki's ingestion rate limit MB/s
- Loki's burst rate limit MB/s
- Graph of logs rejected by Loki for being over the rate limit
- Graph of logs dropped by Alloy (should be 0 because Alloy performs retries)

### View the logs
In the logs, will see that Alloy gets rate-limited by Loki:

```
podman-compose logs alloy
```

> ts=2025-02-15T13:01:03.371548868Z level=warn msg="error sending batch, will retry" component_path=/ component_id=loki.write.local component=client host=loki:3100 status=429 tenant="" error="server returned HTTP status 429 Too Many Requests (429): Ingestion rate limit exceeded for user fake (limit: 1048 bytes/sec) while attempting to ingest '186' lines totaling '10230' bytes, reduce log volume or contact your Loki administrator to see if the limit can be increased"

But log batches are retried - no logs are dropped. Check the `loki_write_dropped_bytes_total` metric in Alloy:

```
$ curl -s localhost:12346/metrics | grep loki_write_dropped_bytes_total
# HELP loki_write_dropped_bytes_total Number of bytes dropped because failed to be sent to the ingester after all retries.
# TYPE loki_write_dropped_bytes_total counter
loki_write_dropped_bytes_total{component_id="loki.write.local",component_path="/",host="loki:3100",reason="ingester_error",tenant=""} 0
loki_write_dropped_bytes_total{component_id="loki.write.local",component_path="/",host="loki:3100",reason="line_too_long",tenant=""} 0
loki_write_dropped_bytes_total{component_id="loki.write.local",component_path="/",host="loki:3100",reason="rate_limited",tenant=""} 0
loki_write_dropped_bytes_total{component_id="loki.write.local",component_path="/",host="loki:3100",reason="stream_limited",tenant=""} 0
```

If Alloy is dropping logs, you'll see "final error sending batch" in the logs:

> ts=2025-02-16T11:40:45.539893611Z level=error msg="final error sending batch" component_path=/ component_id=loki.write.local component=client host=loki:3100 status=429 tenant="" error="server returned HTTP status 429 Too Many Requests (429): Ingestion rate limit exceeded for user fake (limit: 2097 bytes/sec) while attempting to ingest '9' lines totaling '9306' bytes, reduce log volume or contact your Loki administrator to see if the limit can be increased"

Other useful links:

- http://localhost:9090/targets - Show Prometheus targets (Loki and Alloy)
