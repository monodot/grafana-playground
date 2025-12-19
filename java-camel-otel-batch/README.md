---
keywords: [camel, opentelemetry, jms, activemq, postgresql, batch-processing, java, spring-boot]
---

# Apache Camel Batch Processing with OpenTelemetry

Demonstrates instrumenting an Apache Camel route that performs batch processing from PostgreSQL to ActiveMQ with OpenTelemetry traces, metrics, and logs.

This demo shows:

- Apache Camel routes with OpenTelemetry automatic instrumentation
- Scheduled job that creates orders and sends them to ActiveMQ Artemis via JMS
- Consumer route that reads from JMS queue and persists to PostgreSQL
- HTTP client making periodic requests to external API
- Full observability with traces, metrics, and logs exported to Grafana Cloud stack

This demo also uses the experimental setting `otel.instrumentation.messaging.experimental.receive-telemetry.enabled`. See: https://opentelemetry.io/docs/zero-code/java/agent/instrumentation/#capturing-consumer-message-receive-telemetry-in-messaging-instrumentations

## Getting Started

Start the demo:

```bash
podman-compose up --build
```

Stop the demo:

```bash
podman-compose down -v
```

Access Grafana at http://localhost:3000
