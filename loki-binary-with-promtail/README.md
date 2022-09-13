# loki-local

Running a local instance of Loki using the binary distribution, with Promtail as a log collector.

## Getting started

We will:

- Download and run Loki
- Download and run Promtail, configured to gather logs from /var/log and the system journal.
- Observe the logs using the Loki API.

### Download and run Loki

```
curl -O -L "https://github.com/grafana/loki/releases/download/v2.6.1/loki-linux-amd64.zip"
unzip loki-linux-amd64.zip

chmod a+x loki-linux-amd64
sudo mv loki-linux-amd64 /usr/local/bin/loki
```

Start Loki:

```
loki -config.file=loki-local-config.yaml
```

Now you can test it out - check the `/ready` endpoint and see if there are any _labels_ -- it should be empty as it's a new instance of Loki:

```
$ curl http://localhost:3100/ready
ready
$ curl http://localhost:3100/loki/api/v1/labels
{"status":"success"}
```

### Download and run Promtail

Download the Promtail distribution, extract the binary and move to /usr/local/bin:

```
curl -OL https://github.com/grafana/loki/releases/download/v2.6.1/promtail-linux-amd64.zip

unzip promtail-linux-amd64.zip

chmod a+x promtail-linux-amd64
sudo mv promtail-linux-amd64 /usr/local/bin/promtail
```

Start Promtail with our sample config (which collects logs from /var/log, and the system journal):

```
promtail -config.file=promtail-config.yaml
```

OR, to send to a [Grafana Cloud][cloud] instance of Loki:

```
export LOKI_USERNAME=yourUserID
export LOKI_PASSWORD=your_grafana_cloud_api_key

promtail -config.file=promtail-config-cloud.yaml -config.expand-env=true
```

#### Promtail config

The Promtail config file tells Promtail to collect and relabel logs:

- When Promtail reads from the journal, it brings in all fields prefixed with __journal_ as internal labels. [^1]

- Labels prefixed with __ are dropped, so relabeling is required to keep these labels. [^1]

- The example config file relabels the journal label `SYSLOG_IDENTIFIER`, so that it can be seen in Loki. This is a useful label, it's sometimes holds the name of the process or task that wrote the log entry:

    ```
    $ journalctl -F SYSLOG_IDENTIFIER
    systemd-oomd
    systemd-sleep
    systemd-shutdown
    udisksd
    systemd-coredump
    fprintd
    ```

### Find some data in Loki

After a short while you should see some labels appearing in Loki:

```
$ curl http://localhost:3100/loki/api/v1/labels | jq
{
  "status": "success",
  "data": [
    "filename",
    "job",
    "unit"
  ]
}
```

Let's query one of those labels, `filename`:

```
$ curl http://localhost:3100/loki/api/v1/label/filename/values | jq
{
  "status": "success",
  "data": [
    "/var/log/dnf.librepo.log",
    "/var/log/dnf.log",
    "/var/log/dnf.rpm.log",
    "/var/log/hawkey.log"
  ]
}

$ curl -G http://localhost:3100/loki/api/v1/query --data-urlencode 'query={filename="/var/log/dnf.log"}' | jq
{
  "status": "success",
  "data": {
    "resultType": "streams",
    "result": [],
    "stats": {
      "summary": {
        "bytesProcessedPerSecond": 0,
        "linesProcessedPerSecond": 0
        // ...
}
```


[^1]: https://grafana.com/docs/loki/latest/clients/promtail/scraping/

[cloud]: https://grafana.com/products/cloud/
