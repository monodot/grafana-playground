# loki-labels-demo

This demo [Compose][compose] project shows how to use Promtail to read application log files, add labels and send to Grafana Cloud Logs or Loki. Uses:

- [Promtail][promtail] - the official client for sending logs to Loki and Grafana Cloud Logs

- [Flog][flog] - a fake log generator

## Getting started

1.  Sign up for a Grafana Cloud account at https://grafana.com and then create an API key with the _MetricsPublisher_ role.

    **OR**
    
    Deploy your own instance of Loki. 

1.  Make a copy of the file `.env.example`, edit the values to suit your environment, and save it as `.env`.

2.  Run with docker compose or Podman compose:

    ```shell
    docker compose up

    podman-compose up
    ```

[compose]: https://compose-spec.io/
[promtail]: https://grafana.com/docs/loki/latest/clients/promtail/configuration/
[flog]: https://github.com/mingrammer/flog
