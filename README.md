# grafana-demos

Demos of doing things with Grafana and the LGTM stack (Loki, Grafana, Tempo, Mimir).

**⚠ Most of these demos are incomplete. They are just skeleton setups to make it easier to do a bit of learning and exploration with the LGTM stack. Use at your own risk!**

| *Demo* | *Description* |
| --- | --- |
| [Loki basic demo with Docker Compose](loki-docker-compose/README.md) | Runs Loki, Promtail and Grafana in containers with Docker Compose. |
| [Loki binary deployment with Promtail](loki-binary-with-promtail/README.md) | Runs Loki and Promtail from the binary releases, collecting Linux logs from /var/log and the system journal. |
| [Loki deletion with single store](loki-single-store-deletion/README.md) | Investigating how deletion works in Loki. |
