# Beyla: Context propagation demo

Demonstration of propagation of trace context between services with Beyla (OBI) in containers.

Beyla instruments two containers and injects W3C TraceContext headers into the outgoing call from the included Node.js application, allowing traces from both applications to be correlated in Tempo.

![](./diagram.png)

## Getting started

Run the following command to start the services:

```shell
docker compose up
```

Or if you're using podman - don't forget to run as root since we need a privileged container for Beyla:

```shell
sudo podman-compose up
```

### Send test requests

Send a request to NGINX:

```shell
curl localhost:18080/search
```

### Find the trace

Open Grafana at http://localhost:3000. Navigate to Drilldown -> Traces and look for **nginx** service traces. You should find a trace like this:

![](./trace.png)
