# Repository instructions

## Creating a new demo

A new demo should:

- Live in its own directory (e.g. `loki-missing-logs`, `grafana-keycloak`)
- Have a README.md with: the title of the demo in H1, and a brief sentence describing the demo underneath. Followed by the rest of the instructions.
- Start with a `compose.yaml`
- Assume Podman; use explicit image URLs (e.g. `docker.io/library/appname`) and explicit bind volume labelling
- Use the `grafana/otel-lgtm:latest` if this demo requires a local instance of Grafana, Loki, Tempo, Mimir. It includes Grafana (port 3000) and an OTLP endpoint (port 4317)
- Once the demo's README has been generated, run `./gendocs.py` to regenerate the root README.md
