# loki-single-store-deletion (incomplete)

_Single Store_ is the name for a configuration variant of Loki, where the chunk store is configured to hold both chunks **and** the index.

A demo to explore how old data is deleted/pruned in Loki.

## To run (unsanitised notes)

1.  Start Loki with the [config](config.yaml) in this directory
1.  Run Prometheus locally and get it to scrape Loki's metrics endpoint, so we can see some metrics about Loki itself.
1.  Configure Promtail to put some logs into Loki (e.g. systemd journal) - TODO
1.  Start up a grafana instance and add Prometheus as a data source - TODO
1.  Wait 24h to see if the compactor prunes old log data - TODO

Download the Loki and Prometheus binaries, then:

```bash
sudo mkdir -p /opt/loki /opt/prometheus
sudo chown -R yourusername:yourusername /opt/loki /opt/prometheus

# Run Loki with the config file config.yaml in $PWD
nohup loki > loki.out &

# Run Prometheus with the included config file
nohup prometheus --config.file=prometheus.yaml --storage.tsdb.path="/opt/prometheus/metrics2" > prometheus.out &
```

