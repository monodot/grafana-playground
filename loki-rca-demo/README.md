# Loki RCA demo

## Getting started

Bring up the configuration:

```shell
podman-compose up
```

Test the ingester service:

```shell
curl localhost:8080/ingest -d 'big document thingy'
```
