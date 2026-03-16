# Beyla: Context propagation demo

Demonstration of propagation of trace context between services with Beyla (OBI) in containers.

Beyla instruments 4 apps and injects W3C TraceContext headers into the outgoing call from the included Node.js and Java applications, allowing traces from both applications to be correlated in Tempo.

![](./diagram.png)

The services:

- **nginx**: the entry point to the application. You can hit the endpoints `/search` and `/catalog`.
- **node-client**: receives requests from nginx, acts as a gateway to the other two services
- **java-server**: instrumented with Beyla only
- **java-otel-server**: instrumented with the OpenTelemetry Java Agent. This service uses Tomcat as the web server, so that we can see instrumentation.

## Getting started

Run the following command to start the services:

```shell
docker compose up
```

Or if you're using podman, run as root, since we need a privileged container for Beyla:

```shell
sudo podman-compose up -d --build
```

Check all the containers are running:

```shell
sudo podman ps
```

Then, to tear down:

```shell
sudo podman-compose down
```

Grab the Beyla logs if you need them for debugging:

```shell
sudo podman-compose logs beyla | tee beyla.log
```

### Send test requests

Send a request to NGINX:

```shell
curl localhost:18080/search
```

Send a request which routes to the Java service which is instrumented with the OTel Java agent:

```shell
curl localhost:18080/catalog
```

### Find the trace

Wait a few seconds for the trace to be flushed and exported.

Then, open Grafana at http://localhost:3000. Navigate to Drilldown -> Traces and look for **nginx** service traces. You should find a trace like this:

![](./trace.png)

## Troubleshooting

Traces are missing:

- Wait a few seconds for traces to be exported
- Ensure you're running the containers as root, since Beyla requires privileged containers to be able to attach to processes
