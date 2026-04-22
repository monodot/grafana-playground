# VictoriaLogs: Sending OTLP logs and querying in Grafana

Runs a local VictoriaLogs instance, receiving OTLP logs from _telemetrygen_, with Prometheus for monitoring the VL instance. Queries the logs and metrics in Grafana.

## Getting started

Bring it up:

```shell
podman-compose up
```

Then open Grafana and try querying the _victoria-logs_ datasource:

```
* AND service.name:="telemetrygen" AND severity_text:="Info"

* | facets
```

Then you can access the VictoriaLogs UI at <http://localhost:9428/select/vmui/>.

To query VictoriaLogs metrics, check Drilldown Metrics in Grafana:

- `vl_rows_ingested_total` - gives the number of log entries that were successfully ingested.
- `vl_bytes_ingested_total` - gives an estimated size of the ingested log entries, as JSON.

For example, to get the per-second rate of log bytes ingested:

```promql
sum(rate(vl_bytes_ingested_total{ instance="victoria-logs:9428"}[$__rate_interval]))
```

Or access VictoriaLogs metrics directly at <http://localhost:9428/metrics>.

## Tidying up

```shell
podman-compose down
```
