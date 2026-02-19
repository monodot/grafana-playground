# Lambda Java instrumented with AWS Distribution of OpenTelemetry (ADOT)

This example shows how to add the ADOT Lambda layer to a Java application and ship traces and logs directly to Grafana Cloud's OTLP endpoint.

## Prerequisites

You need to have these installed locally so that a JAR can be produced:

- Java

## To deploy

To deploy:

```shell
tofu init

tofu apply
```

