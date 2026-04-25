# grafana-openapi-client-go: testing the client

Demonstrates how `grafana-openapi-client-go` interacts with a fake Grafana backend, provided by WireMock.

This demo was initially created to see how a PR fixes an issue with the client's retry behaviour. 

## Running

```bash
podman-compose up --build
```

Or with Docker:

```bash
docker compose up --build
```

The `runner` container exits after printing its output. To see the logs clearly:

```bash
podman-compose up --build --abort-on-container-exit 2>&1 | grep runner
```

## Resetting and re-running

WireMock scenarios are reset between the two runs by the Go program itself (via `POST /__admin/scenarios/reset`). To run again from scratch, just restart the compose stack:

```bash
podman-compose down && podman-compose up --build
```
