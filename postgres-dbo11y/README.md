# PostgreSQL: Database Observability with Alloy and Grafana Cloud

## Getting started

Bring up the demo - note that you'll need to ping the test app at http://localhost:3000/snacks locally.

```sh
podman compose up
```

Or, run with a k6 load test, to simulate some database traffic:

```sh
podman compose --profile load-test up
```

## Troubleshooting

- Check that you've not required SSL in your connection string, but the databae is configured without SSL - e.g. `sslmode=require`
