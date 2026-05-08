# Beyla: HTTP body attribute extraction

Shows how to use Beyla and Alloy to extract attributes from HTTP bodies, using `enrichment` and OTTL.

- Uses payload extraction in Beyla/OBI to get the request JSON payload for a service
- Uses OTTL in Alloy to parse the body, storing individual fields as span attributes

## Getting started

Run the following command to start the services:

```shell
docker compose up
```

Or if you're using podman, run as root, since we need a privileged container for Beyla:

```shell
sudo podman-compose up -d --build
```

Wait 30 seconds for the services to start and begin shipping traces.

Then visit Traces Drilldown and find a `POST /customers` trace to see that the attributes were extracted:

![Screenshot of the trace in Traces Drilldown](screenshot.webp)

Grab the Beyla logs if you need them for debugging:

```shell
sudo podman-compose logs beyla | tee beyla.log
```

## Tear down

To tear down:

```shell
sudo podman-compose down
```
