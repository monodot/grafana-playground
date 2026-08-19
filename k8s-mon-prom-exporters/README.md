# Kubernetes Monitoring with an existing OpenTelemetry Collector and Prometheus exporters

Adds Grafana Cloud Kubernetes Monitoring to an OpenTelemetry Collector setup that already exists in a cluster, without adding new Collector instances or duplicating exporters that are already installed.

## The scenario

- kube-state-metrics and node-exporter are already installed (this demo installs them separately, to mimic a pre-existing installation)
- otelcol is already running as a central Deployment and DaemonSet
- we want to avoid deploying any new collectors or agents
- we scrape targets and set up pipelines required to ship the required metrics to Grafana Cloud for Kubernetes Monitoring

## Set up

Create the cluster:

```shell
kind create cluster --config kind-cluster.yaml
```

Install `kube-state-metrics` and `node-exporter`. In a real cluster with Rancher monitoring, these would already be present, so this step would be skipped:

```shell
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install ksm prometheus-community/kube-state-metrics -n default
helm install nodeexporter prometheus-community/prometheus-node-exporter -n default
```

Deploy the existing backend:

```shell
kubectl apply -f manifests/existing-backend.yaml
```

Install the two OTel Collectors with their current (pre-Grafana Cloud) configuration:

```shell
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm repo update
helm install otelcol-metrics open-telemetry/opentelemetry-collector -n default -f helm/metrics-deployment/values-existing.yaml
helm install otelcol-logs open-telemetry/opentelemetry-collector -n default -f helm/logs-daemonset/values-existing.yaml
```

Wait for all Pods to be ready, then confirm both Collectors are exporting without errors:

```shell
kubectl rollout status deploy/otelcol-metrics-opentelemetry-collector
kubectl rollout status daemonset/otelcol-logs-opentelemetry-collector-agent

kubectl logs deploy/otelcol-metrics-opentelemetry-collector | grep -i error
kubectl logs daemonset/otelcol-logs-opentelemetry-collector-agent | grep -i error
```

No output means both are sending cleanly to the existing backend.

## Add Grafana Cloud

Copy `.env.example` to `.env`, fill in the values from your Grafana Cloud stack, then load them into your shell:

```shell
set -a; source .env; set +a
```

Render the two `.tmpl` files, substituting only the variables from `.env`:

```shell
VARS='$GRAFANA_CLOUD_CLUSTER_NAME $GRAFANA_CLOUD_PROMETHEUS_URL $GRAFANA_CLOUD_PROMETHEUS_USERNAME $GRAFANA_CLOUD_PROMETHEUS_TOKEN $GRAFANA_CLOUD_OTLP_ENDPOINT $GRAFANA_CLOUD_OTLP_USERNAME $GRAFANA_CLOUD_ACCESS_POLICY_TOKEN'
envsubst "$VARS" < helm/metrics-deployment/values-grafana-cloud.yaml.tmpl > /tmp/otelcol-metrics-grafana-cloud.yaml
envsubst "$VARS" < helm/logs-daemonset/values-grafana-cloud.yaml.tmpl > /tmp/otelcol-logs-grafana-cloud.yaml
```

Upgrade the same two Helm releases in place, just adding to the configuration of the existing otelcol Deployment/DaemonSet:

```shell
helm upgrade otelcol-metrics open-telemetry/opentelemetry-collector -n default -f /tmp/otelcol-metrics-grafana-cloud.yaml
helm upgrade otelcol-logs open-telemetry/opentelemetry-collector -n default -f /tmp/otelcol-logs-grafana-cloud.yaml
```

Wait for the Pods to restart, then check both destinations: the same error check as above for the existing backend, and Grafana Cloud's **Observability** > **Kubernetes** page for the new data.

## Tear down

Delete the cluster:

```shell
kind delete cluster --name prom-exporter-demo
```
