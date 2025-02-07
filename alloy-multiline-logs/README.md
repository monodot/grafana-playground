# alloy-multiline-logs

Shows how to use Grafana Alloy to collect logs from an application, where the logs are in a multi-line format and need to be merged before sending to Loki.

## Prerequisites

- Docker
- Docker Compose
- logcli (from the Grafana Loki distribution)

## How to run

```shell
podman-compose up

logcli series '{}'
# should return:
# {demo="alloy-multiline-logs", filename="/var/log/shared/app.log", repo="monodot/grafana-playground"}

logcli query --tail '{demo="alloy-multiline-logs"}'
```

The query should output log lines like this:

```
2025-02-07T16:02:11Z {demo="alloy-multiline-logs", filename="/var/log/shared/app.log", repo="monodot/grafana-playground"} 2025-02-07T16:02:11+00:00 New log entry with
    multiline fun,
    carrots,
    pineapple,
      and
    bananas
2025-02-07T16:02:16Z {demo="alloy-multiline-logs", filename="/var/log/shared/app.log", repo="monodot/grafana-playground"} 2025-02-07T16:02:16+00:00 New log entry with
    multiline fun,
    carrots,
    pineapple,
      and
    bananas
2025-02-07T16:02:21Z {demo="alloy-multiline-logs", filename="/var/log/shared/app.log", repo="monodot/grafana-playground"} 2025-02-07T16:02:21+00:00 New log entry with
    multiline fun,
    carrots,
    pineapple,
      and
    bananas
```
