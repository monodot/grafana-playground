# alloy-loki-drop-logs-time

Shows how to drop logs in Alloy based on the hour of the day.

## Prerequisites

- Docker
- Docker Compose

## How to run

```shell
podman-compose up
```

In this example, Alloy inspects the timestamp of the log, and drops logs outside the hours between 9am and 6pm. You can see this in the config.alloy file:

```
stage.drop {
  source = "mytime"
  expression = "\\d{4}-\\d{2}-\\d{2}T(0[0-8]|1[8-9]|2[0-3]):\\d{2}:\\d{2}" // Drop between 18:00 and 09:00
  drop_counter_reason = "log_outside_desired_time_range"
}
```

**Suggestion:** Try modifying this expression to drop logs in your current hour of the day. Run the demo and keep it running until the next hour. When the next hour starts, the logs will no longer be dropped.

#### Observing the count of dropped logs

Alloy will drop logs that are outside the desired time range. You can see the count of dropped logs by querying the `loki_process_dropped_lines_total` metric:

```
$ curl -s localhost:12346/metrics | grep drop
# HELP loki_process_dropped_lines_total A count of all log lines dropped as a result of a pipeline stage
# TYPE loki_process_dropped_lines_total counter
loki_process_dropped_lines_total{component_id="loki.process.local",component_path="/",reason="log_outside_desired_time_range"} 8
```

