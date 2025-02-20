# loki-alert-missing-log

A demo showing how to alert on a missing log (e.g. a job that didn't complete).

## Running the demo

First, ensure you've set these environment variables:

    GRAFANA_CLOUD_API_KEY=...
    GRAFANA_CLOUD_LOGS_ID=...
    GRAFANA_CLOUD_LOGS_URL=...

Then, start Alloy and the demo app:

```shell
podman-compose up
```

### Creating demo jobs

The Compose configuration includes a demo app that generates job logs. It port-forwards to port 3001 on your local machine. 

Create a job that succeeds:

```shell
curl -X POST --location "http://localhost:3001/api/jobs" \
    -H "Content-Type: application/json" \
    -d '{
          "name": "data-processing",
          "duration": 5000,
          "shouldSucceed": true
        }'
```

Create a job that fails:

```shell
curl -X POST --location "http://localhost:3001/api/jobs" \
    -H "Content-Type: application/json" \
    -d '{
          "name": "data-processing",
          "duration": 5000,
          "shouldSucceed": false
        }'
```

The app will emit logs like this:

```
2025-02-20 11:03:14.887	
Job API server running on port 3000
2025-02-20 11:03:26.916	
job="data-processing" jobId=f2297715-c919-48a1-a60a-5d164ec1b83e event=started at 2025-02-20T11:03:26.739Z
2025-02-20 11:03:31.931	
✅ SUCCESS: job="data-processing" jobId=f2297715-c919-48a1-a60a-5d164ec1b83e event=completed-successfully after 5000ms at 2025-02-20T11:03:31.744Z
2025-02-20 11:07:25.083	
job="data-processing" jobId=64061cd8-9a0c-43bd-a451-e1f6e6ac7671 event=started at 2025-02-20T11:07:24.862Z
```

### Find all jobs which started but didn't finish

In Grafana, run this LogQL query (ensure you have **Instant** type selected), which will find all jobs which have a "started" event, but no "completed-successfully" event:

```
sum by (jobId) (
  count_over_time({service_name="loki-alert-missing-log"} | logfmt | event=`started` [12h])
)
unless
sum by (jobId) (
  count_over_time({service_name="loki-alert-missing-log"} | logfmt | event=`completed-successfully` [12h])
) 
> 0
```

This query will generate a table of results like this (presented here as CSV) - correctly identifying `7671` as the job that didn't complete:

```csv
"Time","jobId","Value #combined"
2025-02-20 11:23:30,64061cd8-9a0c-43bd-a451-e1f6e6ac7671,1
```

