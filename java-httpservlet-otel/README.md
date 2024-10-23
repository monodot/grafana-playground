# Java: Tomcat servlet logs with OpenTelemetry

This project demonstrates how to monitor a simple Java servlet running on Tomcat using the OpenTelemetry Java agent. It collects the telemetry via Alloy, which sends it to Grafana Cloud for visualisation.

To run:

```
podman-compose up
```

Then search in Grafana Cloud Logs:

```
{service_name="hello-servlet"}
```

And you should see OpenTelemetry logs like this:

```json
{
  "body": "Received hello request",
  "traceid": "289cb05c60c44e14974d7023860e2598",
  "spanid": "a868cb886672a21f",
  "severity": "INFO",
  "resources": {
    "container.id": "15ca34e77bd75540ac24195211ac4f28f82aa4d58397dd51d81becf79965873d",
    "host.arch": "amd64",
    "host.name": "4cb7a7505021",
    "service.instance.id": "7efcb0b3-a7c0-4a25-a6be-cbb090df1c93",
    "service.name": "hello-servlet",
    "telemetry.distro.name": "opentelemetry-java-instrumentation",
    "telemetry.distro.version": "2.8.0",
    "telemetry.sdk.language": "java",
    "telemetry.sdk.name": "opentelemetry",
    "telemetry.sdk.version": "1.42.1"
  },
  "instrumentation_scope": { "name": "org.example.HelloServlet" }
}
```
