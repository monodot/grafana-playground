# Grafana SQL Expressions: Joining Logs

A demo that shows how to use Grafana's SQL Expressions feature to join two different log queries by a common label into a single table view.

## Overview

This demo runs a job simulator that:

- Starts a new job approximately every 10 seconds
- Each job runs for 10 seconds to 2 minutes
- Jobs complete with `success` (95%) or `error` (5%) status
- Logs are shipped via OpenTelemetry to Loki

In Grafana, SQL Expressions join the start and end logs by `job_id` to create a unified view showing job duration and status.

## Running the Demo

```bash
docker compose up -d
```

Open Grafana at http://localhost:3000

Navigate to Dashboards -> Job monitor to see the result.

Edit the main Table panel to see how it works!

## Cleanup

```bash
docker compose down
```
