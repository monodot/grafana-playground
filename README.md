# grafana-playground

Demos of doing things with Grafana and the LGTM stack (Loki, Grafana, Tempo, Mimir).

**⚠ Most of these demos are incomplete. They are just skeleton setups to make it easier to do a bit of learning and exploration with the LGTM stack. Use at your own risk!**

<!-- BEGIN_LIST -->
| Path | Description | Last Updated |
|------|-------------|--------------|
| [alloy-cloudwatch-loki-labels](alloy-cloudwatch-loki-labels/README.md) | **Alloy: Consume logs from CloudWatch and extract labels**<br>This example shows how to deploy Alloy to consume logs from CloudWatch using the OpenTelemetry CloudWatch receiver, and extract the `service.name` attribute from the CloudWatch log group name. | 2025-06-26 |
| [alloy-helm-gcplogs](alloy-helm-gcplogs/README.md) | **alloy-helm-gcplogs**<br>Shows how to deploy Alloy with the Helm chart, configured with authentication to Google Cloud Platform to pull logs from a PubSub topic. | 2025-11-28 |
| [alloy-loki-drop-logs-time](alloy-loki-drop-logs-time/README.md) | **alloy-loki-drop-logs-time**<br>Shows how to drop logs in Alloy based on the hour of the day. | 2025-11-28 |
| [alloy-multiline-logs](alloy-multiline-logs/README.md) | **alloy-multiline-logs**<br>Shows how to use Grafana Alloy to collect logs from an application, where the logs are in a multi-line format and need to be merged before sending to Loki. | 2025-02-12 |
| [alloy-otlp-logs-attributes](alloy-otlp-logs-attributes/README.md) | **Alloy: Drop unwanted OTLP logs attributes**<br>Demonstrates how to use OTTL statements to filter and retain only specific log attributes when processing OTLP logs using Grafana Alloy. | 2025-12-03 |
| [aws-ecs-ec2-alloy](aws-ecs-ec2-alloy/README.md) | **AWS: Send logs from an ECS task on EC2 to Grafana Cloud Logs with Grafana Alloy**<br>This example shows how to collect logs from tasks running on ECS EC2 instances, using Grafana Alloy running as a Daemon on the VM. | 2024-10-16 |
| [aws-ecs-fargate-demos](aws-ecs-fargate-demos/README.md) | **AWS ECS Fargate demos**<br>This repository contains demonstrations of different ways to ship telemetry from AWS ECS Fargate to Grafana Cloud or the Grafana LGTM stack. | 2025-11-28 |
| [dotnet-kafka-otel](dotnet-kafka-otel/README.md) | **.NET Core 10: Kafka consumer example**<br>Example .NET Core application which consumes messages from a Kafka topic, instrumented with OpenTelemetry. | 2025-11-28 |
| [dotnetfx48-demo](dotnetfx48-demo/README.md) | **.NET Framework 4.8 demo**<br>The included Dockerfile shows how to add OpenTelemetry instrumentation to a .NET Framework 4.8 app running inside a Windows container. | 2025-12-01 |
| [enterprise-logs-k8s-manifests-1.6.0](enterprise-logs-k8s-manifests-1.6.0/README.md) | **Grafana Enterprise Logs 1.6.0 + Minio on Kubernetes**<br>This quick demo deploys Grafana Enterprise Logs 1.6.0 with Minio storage backend on Kubernetes, exposed publicly through an external LoadBalancer. | 2024-04-25 |
| [gel-on-gke](gel-on-gke/README.md) | **gel-on-gke**<br>A journal from deploying the following on Kubernetes on Google Cloud: | 2022-10-26 |
| [go-kafka-otel](go-kafka-otel/README.md) | **Kafka Client OpenTelemetry Traces with Beyla**<br>This example demonstrates generating a distributed trace that spans HTTP requests and Kafka messaging, using the segmentio/kafka-go library. The setup consists of: | 2025-11-27 |
| [grafana-keycloak-oauth](grafana-keycloak-oauth/README.md) | **Grafana + SSO with Keycloak**<br>A local Compose configuration showing how to | 2024-09-23 |
| [java-httpservlet-otel](java-httpservlet-otel/README.md) | **Java: Tomcat servlet logs with OpenTelemetry**<br>This project demonstrates how to monitor a simple Java servlet running on Tomcat using the OpenTelemetry Java agent. It collects the telemetry via Alloy, which sends it to Grafana Cloud for visualisation. | 2024-10-23 |
| [java-spring-otel](java-spring-otel/README.md) | **java-spring-otel**<br>Demo of collecting traces, logs and metrics from a Java application and sending them to Grafana Cloud. | 2025-02-12 |
| [logs-lbac](logs-lbac/README.md) | **logs-lbac (Label-Based Access Control)**<br>This demo shows how to restrict access to logs in Grafana Cloud Logs, using Cloud Access Policies. | 2023-05-15 |
| [logs-promtail-examples](logs-promtail-examples/README.md) | **logs-promtail-examples**<br>This demo Compose project shows how to use Promtail to read application log files, and send them to Grafana Cloud Logs or Loki. It also shows how to use the features of Promtail to add extra labels, and parse log lines. | 2025-02-12 |
| [loki-alert-missing-log](loki-alert-missing-log/README.md) | **loki-alert-missing-log**<br>A demo showing how to alert on a missing log (e.g. a job that didn't complete). | 2025-02-20 |
| [loki-binary-with-promtail](loki-binary-with-promtail/README.md) | **loki-local**<br>Running a local instance of Loki using the binary distribution, with Promtail as a log collector. | 2022-09-13 |
| [loki-docker-compose](loki-docker-compose/README.md) | **loki-docker-compose**<br>Run Loki, Promtail and Grafana in containers. | 2023-09-20 |
| [loki-fluentbit-metadata](loki-fluentbit-metadata/README.md) | **Fluent Bit: Parsing and sending structured metadata to Loki**<br>This Compose example shows how to use Fluent Bit's Loki plugin to parse incoming JSON logs, and attach two pieces of _Structured Metadata_ to each log line. | 2024-10-23 |
| [loki-k8s-fluentbit](loki-k8s-fluentbit/README.md) | **Kubernetes -> Fluent Bit -> Loki**<br>This example shows how to deploy Fluent Bit with the Loki output plugin to send logs to Loki or Grafana Cloud Logs. | 2023-10-16 |
| [loki-mock-logs](loki-mock-logs/README.md) | **mock logs**<br>Deploy a stacktrace generator: | 2024-03-15 |
| [loki-otlp-labels](loki-otlp-labels/README.md) | **Loki: Promote custom OpenTelemetry resource attributes to labels**<br>How to use Alloy to set a custom OpenTelemetry _Resource Attribute_, and then get Loki/GEL to automatically promote the attribute to a label, instead of structured metadata. | 2024-10-23 |
| [loki-rate-limit-alloy](loki-rate-limit-alloy/README.md) | **loki-rate-limit-alloy**<br>Shows how rate limiting works in Loki and Alloy. Sets an arbitrary rate limit in Loki. Then sends more than this in bursts, and observes how Loki and Alloy handle the rate limiting. | 2025-02-19 |
| [loki-single-store-deletion](loki-single-store-deletion/README.md) | **loki-single-store-deletion (incomplete)**<br>_Single Store_ is the name for a configuration variant of Loki, where the chunk store is configured to hold both chunks **and** the index. | 2022-10-26 |
| [otel-aws-sqs-example](otel-aws-sqs-example/README.md) | **OpenTelemetry AWS SQS Example**<br>Example of configuring the OpenTelemetry `aws-sdk` Instrumentation for Node.js, to add trace context to SQS messages. | 2025-11-28 |
| [php-demo-oteldocs](php-demo-oteldocs/README.md) | **PHP: Demo from OpenTelemetry docs**<br>This directory contains the demo app described in the upstream OpenTelemetry zero-code documentation. | 2025-07-15 |
| [php-slim-apprunner](php-slim-apprunner/README.md) | **PHP Slim Framework demo on AWS App Runner**<br>This repository contains a demonstration of how to deploy a PHP application with OpenTelemetry instrumentation to AWS App Runner and send telemetry data to Grafana Cloud. | 2025-07-16 |
| [terraform-basic](terraform-basic/README.md) | **Terraform: Basic example**<br>This example Terraform configuration creates 2 stacks in a Grafana Cloud organization. | 2025-12-02 |
| [terraform-basic-json](terraform-basic-json/README.md) | **Terraform: Basic example in JSON language**<br>This example Terraform configuration uses the JSON syntax to create 1 stack in a Grafana Cloud organization. | 2024-04-26 |
| [terraform-stack-loki-lbac](terraform-stack-loki-lbac/README.md) | **Terraform: create stack and set up LBAC for Loki**<br>This is an example Terraform configuration for setting up Loki LBAC in Grafana Cloud. | 2024-02-19 |
<!-- END_LIST -->
