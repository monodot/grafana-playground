# grafana-demos

Demos of doing things with Grafana and the LGTM stack (Loki, Grafana, Tempo, Mimir).

**⚠ Most of these demos are incomplete. They are just skeleton setups to make it easier to do a bit of learning and exploration with the LGTM stack. Use at your own risk!**

| *Demo* | *Description* |
| --- | --- |
| [Loki basic demo with Docker Compose](loki-docker-compose/README.md) | Runs Loki, Promtail and Grafana in containers with Docker Compose. |
| [Loki binary deployment with Promtail](loki-binary-with-promtail/README.md) | Runs Loki and Promtail from the binary releases, collecting Linux logs from /var/log and the system journal. |
| [Loki deletion with single store](loki-single-store-deletion/README.md) | Investigating how deletion works in Loki. |
| [Logs Promtail examples](logs-promtail-examples/README.md) | Shows how to use Promtail to read application log files, do some simple processing with pipelines, and send them to Grafana Cloud Logs or Loki. |
| [Logs label-based access control](logs-lbac/README.md) | Shows how to restrict access to logs in Grafana Cloud Logs, using Cloud Access Policies. |
