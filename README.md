# grafana-playground

Demos of doing things with Grafana and the LGTM stack (Loki, Grafana, Tempo, Mimir).

**⚠ Most of these demos are incomplete. They are just skeleton setups to make it easier to do a bit of learning and exploration with the LGTM stack. Use at your own risk!**

<!-- BEGIN_LIST -->
| Path | Description | Last Updated |
|------|-------------|--------------|
| [alloy-multiline-logs](alloy-multiline-logs/README.md) | **alloy-multiline-logs**<br>Shows how to use Grafana Alloy to collect logs from an application, where the logs are in a multi-line format and need to be merged before sending to Loki. | 2025-02-12 |
| [aws-ecs-ec2-alloy](aws-ecs-ec2-alloy/README.md) | **AWS: Send logs from an ECS task on EC2 to Grafana Cloud Logs with Grafana Alloy**<br>This example shows how to collect logs from tasks running on ECS EC2 instances, using Grafana Alloy running as a Daemon on the VM. | 2024-10-16 |
| [aws-ecs-fargate-firelens-loki](aws-ecs-fargate-firelens-loki/README.md) | **AWS: Send logs from an ECS Fargate Task to Grafana Cloud Logs using AWS Firelens log router**<br>This uses: | 2023-07-27 |
| [enterprise-logs-k8s-manifests-1.6.0](enterprise-logs-k8s-manifests-1.6.0/README.md) | **Grafana Enterprise Logs 1.6.0 + Minio on Kubernetes**<br>This quick demo deploys Grafana Enterprise Logs 1.6.0 with Minio storage backend on Kubernetes, exposed publicly through an external LoadBalancer. | 2024-04-25 |
| [gel-on-gke](gel-on-gke/README.md) | **gel-on-gke**<br>A journal from deploying the following on Kubernetes on Google Cloud: | 2022-10-26 |
| [grafana-keycloak-oauth](grafana-keycloak-oauth/README.md) | **Grafana + SSO with Keycloak**<br>A local Compose configuration showing how to | 2024-09-23 |
| [java-httpservlet-otel](java-httpservlet-otel/README.md) | **Java: Tomcat servlet logs with OpenTelemetry**<br>This project demonstrates how to monitor a simple Java servlet running on Tomcat using the OpenTelemetry Java agent. It collects the telemetry via Alloy, which sends it to Grafana Cloud for visualisation. | 2024-10-23 |
| [java-spring-otel](java-spring-otel/README.md) | **java-spring-otel**<br>Demo of collecting traces, logs and metrics from a Java application and sending them to Grafana Cloud. | 2025-02-12 |
| [logs-lbac](logs-lbac/README.md) | **logs-lbac (Label-Based Access Control)**<br>This demo shows how to restrict access to logs in Grafana Cloud Logs, using Cloud Access Policies. | 2023-05-15 |
| [logs-promtail-examples](logs-promtail-examples/README.md) | **logs-promtail-examples**<br>This demo Compose project shows how to use Promtail to read application log files, and send them to Grafana Cloud Logs or Loki. It also shows how to use the features of Promtail to add extra labels, and parse log lines. | 2025-02-12 |
| [loki-binary-with-promtail](loki-binary-with-promtail/README.md) | **loki-local**<br>Running a local instance of Loki using the binary distribution, with Promtail as a log collector. | 2022-09-13 |
| [loki-docker-compose](loki-docker-compose/README.md) | **loki-docker-compose**<br>Run Loki, Promtail and Grafana in containers. | 2023-09-20 |
| [loki-fluentbit-metadata](loki-fluentbit-metadata/README.md) | **Fluent Bit: Parsing and sending structured metadata to Loki**<br>This Compose example shows how to use Fluent Bit's Loki plugin to parse incoming JSON logs, and attach two pieces of _Structured Metadata_ to each log line. | 2024-10-23 |
| [loki-k8s-fluentbit](loki-k8s-fluentbit/README.md) | **Kubernetes -> Fluent Bit -> Loki**<br>This example shows how to deploy Fluent Bit with the Loki output plugin to send logs to Loki or Grafana Cloud Logs. | 2023-10-16 |
| [loki-mock-logs](loki-mock-logs/README.md) | **mock logs**<br>Deploy a stacktrace generator: | 2024-03-15 |
| [loki-otlp-labels](loki-otlp-labels/README.md) | **Loki: Promote custom OpenTelemetry resource attributes to labels**<br>How to use Alloy to set a custom OpenTelemetry _Resource Attribute_, and then get Loki/GEL to automatically promote the attribute to a label, instead of structured metadata. | 2024-10-23 |
| [loki-single-store-deletion](loki-single-store-deletion/README.md) | **loki-single-store-deletion (incomplete)**<br>_Single Store_ is the name for a configuration variant of Loki, where the chunk store is configured to hold both chunks **and** the index. | 2022-10-26 |
| [terraform-basic-json](terraform-basic-json/README.md) | **Terraform: Basic example in JSON language**<br>This example Terraform configuration uses the JSON syntax to create 1 stack in a Grafana Cloud organization. | 2024-04-26 |
| [terraform-stack-loki-lbac](terraform-stack-loki-lbac/README.md) | **Terraform: create stack and set up LBAC for Loki**<br>This is an example Terraform configuration for setting up Loki LBAC in Grafana Cloud. | 2024-02-19 |
<!-- END_LIST -->
