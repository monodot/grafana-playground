# grafana-demos

Demos of doing things with Grafana and the LGTM stack (Loki, Grafana, Tempo, Mimir).

**⚠ Most of these demos are incomplete. They are just skeleton setups to make it easier to do a bit of learning and exploration with the LGTM stack. Use at your own risk!**

<!-- BEGIN_LIST -->
| Path | Title | Description |
|------|-------|-------------|
| [alloy-cloudwatch-loki-labels](alloy-cloudwatch-loki-labels/README.md) | Alloy: Consume logs from CloudWatch and extract labels | This example shows how to deploy Alloy to consume logs from CloudWatch and extract labels from the log line. |
| [alloy-kafka-loki](alloy-kafka-loki/README.md) | Demo of multiple Alloy consumers connecting to Kafka | ``` podman exec -it alloy-kafka-loki_kafka_1 bash |
| [aws-ecs-ec2-alloy](aws-ecs-ec2-alloy/README.md) | AWS: Send logs from an ECS task on EC2 to Grafana Cloud Logs with Grafana Alloy | This example shows how to collect logs from tasks running on ECS EC2 instances, using Grafana Alloy running as a Daemon on the VM. |
| [aws-ecs-fargate-firelens-loki](aws-ecs-fargate-firelens-loki/README.md) | AWS: Send logs from an ECS Fargate Task to Grafana Cloud Logs using AWS Firelens log router | This uses: |
| [enterprise-logs-k8s-manifests-1.6.0](enterprise-logs-k8s-manifests-1.6.0/README.md) | Grafana Enterprise Logs 1.6.0 + Minio on Kubernetes | This quick demo deploys Grafana Enterprise Logs 1.6.0 with Minio storage backend on Kubernetes, exposed publicly through an external LoadBalancer. |
| [gel-on-gke](gel-on-gke/README.md) | gel-on-gke | A journal from deploying the following on Kubernetes on Google Cloud: |
| [grafana-enterprise-persistence](grafana-enterprise-persistence/README.md) | grafana-persistence | ```bash # create a persistent volume for your data in /var/lib/grafana (database and plugins) podman network create grafana-persistent podman volume create grafana-storage podman volume create mysql-grafana-storage |
| [grafana-keycloak-oauth](grafana-keycloak-oauth/README.md) | grafana-keycloak-oauth Example | ``` podman-compose up |
| [java-spring-otel](java-spring-otel/README.md) | java-spring-otel | Demo of collecting traces, logs and metrics from a Java application and sending them to [Grafana Cloud][2]. |
| [logs-lbac](logs-lbac/README.md) | logs-lbac (Label-Based Access Control) | This demo shows how to restrict access to logs in Grafana Cloud Logs, using Cloud Access Policies. |
| [logs-promtail-examples](logs-promtail-examples/README.md) | logs-promtail-examples | This demo [Compose][compose] project shows how to use Promtail to read application log files, and send them to Grafana Cloud Logs or Loki. It also shows how to use the features of Promtail to add extra labels, and parse log lines. |
| [loki-binary-with-promtail](loki-binary-with-promtail/README.md) | loki-local | Running a local instance of Loki using the binary distribution, with Promtail as a log collector. |
| [loki-docker-compose](loki-docker-compose/README.md) | loki-docker-compose | Run Loki, Promtail and Grafana in containers. |
| [loki-fluentbit-metadata](loki-fluentbit-metadata/README.md) | Fluent Bit: Parsing and sending structured metadata to Loki | This Compose example shows how to use Fluent Bit's Loki plugin to parse incoming JSON logs, and attach two pieces of _Structured Metadata_ to each log line. |
| [loki-k8s-fluentbit](loki-k8s-fluentbit/README.md) | Kubernetes -> Fluent Bit -> Loki | This example shows how to deploy Fluent Bit with the Loki output plugin to send logs to Loki or Grafana Cloud Logs. |
| [loki-mock-logs](loki-mock-logs/README.md) | mock logs | Deploy a stacktrace generator: |
| [loki-otlp-labels](loki-otlp-labels/README.md) | Setting custom OpenTelemetry Resource Attributes to promote as labels in Loki | This Alloy config and demo app show how to set a Resource Attribute that will be promoted to a label in Loki. |
| [loki-single-store-deletion](loki-single-store-deletion/README.md) | loki-single-store-deletion (incomplete) | _Single Store_ is the name for a configuration variant of Loki, where the chunk store is configured to hold both chunks **and** the index. |
| [terraform-basic-json](terraform-basic-json/README.md) | Terraform: Basic example in JSON language | This example Terraform configuration uses the JSON syntax to create 1 stack in a Grafana Cloud organization. |
| [terraform-multiple-providers](terraform-multiple-providers/README.md) | multiple providers | Using multiple Terraform providers within the same configuration, and observing how that affects provisioning operations. 👀 |
| [terraform-stack-loki-lbac](terraform-stack-loki-lbac/README.md) | Terraform: create stack and set up LBAC for Loki | This is an example Terraform configuration for setting up Loki LBAC in Grafana Cloud. |
<!-- END_LIST -->
