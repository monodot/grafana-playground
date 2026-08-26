---
keywords:
  - kubernetes
  - kind
  - grafana-cloud
  - kube-state-metrics
  - node-exporter
  - alloy
  - loki
---

# Kubernetes Monitoring with existing Prometheus exporters

Demonstrates how Grafana's Kubernetes Monitoring Helm chart can discover and scrape independently managed Prometheus exporters without deploying duplicates, while also collecting pod logs and sending all telemetry to Grafana Cloud.

## Scenario

This demo keeps ownership explicit:

- Helm release `ksm` owns kube-state-metrics.
- Helm release `nodeexporter` owns Prometheus Node Exporter.
- Helm release `k8s-monitoring` owns the metrics and pod-logs Grafana Alloy collectors and the Alloy Operator, and sends telemetry to Grafana Cloud.

The exporters are installed first to represent workloads that already exist in a cluster. The Kubernetes Monitoring chart uses namespace-scoped label matchers to find them, while `telemetryServices.*.deploy: false` prevents the chart from installing its bundled exporters. A separate DaemonSet Alloy collector tails pod log files from each node and writes them to Grafana Cloud Logs.

## Prerequisites

- [kind](https://kind.sigs.k8s.io/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Helm 3](https://helm.sh/docs/intro/install/)
- A Grafana Cloud stack
- A Grafana Cloud access-policy token with the `MetricsPublisher` and `LogsPublisher` scopes

## Set up

Run all commands from this directory.

Create the kind cluster and the namespace used by all three Helm releases:

```shell
kind create cluster --config kind-cluster.yaml
kind get clusters

kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
```

The cluster list should contain `existing-exporters-demo` exactly once.

Add the Prometheus Community repository, then install the two independently managed exporters at pinned versions:

```shell
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update prometheus-community

helm upgrade --install ksm prometheus-community/kube-state-metrics \
  --version 8.4.0 \
  --namespace monitoring \
  --wait --timeout 5m

helm upgrade --install nodeexporter prometheus-community/prometheus-node-exporter \
  --version 4.56.1 \
  --namespace monitoring \
  --wait --timeout 5m
```

Before installing Kubernetes Monitoring, inspect the running pods and confirm that the selectors used in `values.yaml` each return at least one pod:

```shell
kubectl get pods -n monitoring --show-labels

kubectl get pods -n monitoring \
  -l 'app.kubernetes.io/name=kube-state-metrics,app.kubernetes.io/instance=ksm'

kubectl get pods -n monitoring \
  -l 'app.kubernetes.io/name=prometheus-node-exporter,app.kubernetes.io/instance=nodeexporter'
```

Copy the environment template and fill in the values from the **Prometheus** and **Loki** details pages in your Grafana Cloud stack. The URLs must be the full write endpoints ending in `/api/prom/push` and `/loki/api/v1/push`. The same access-policy token is used for both destinations.

```shell
cp .env.example .env
$EDITOR .env
set -a; source .env; set +a

: "${GRAFANA_CLOUD_PROMETHEUS_URL:?set it in .env}"
: "${GRAFANA_CLOUD_PROMETHEUS_USERNAME:?set it in .env}"
: "${GRAFANA_CLOUD_LOKI_URL:?set it in .env}"
: "${GRAFANA_CLOUD_LOKI_USERNAME:?set it in .env}"
: "${GRAFANA_CLOUD_ACCESS_POLICY_TOKEN:?set it in .env}"
```

Create or update the Secrets referenced by the metrics and logs destinations. These commands are safe to rerun and do not render credentials into a checked-in values file:

```shell
kubectl create secret generic grafana-cloud-metrics \
  --namespace monitoring \
  --from-literal=url="$GRAFANA_CLOUD_PROMETHEUS_URL" \
  --from-literal=username="$GRAFANA_CLOUD_PROMETHEUS_USERNAME" \
  --from-literal=password="$GRAFANA_CLOUD_ACCESS_POLICY_TOKEN" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic grafana-cloud-logs \
  --namespace monitoring \
  --from-literal=url="$GRAFANA_CLOUD_LOKI_URL" \
  --from-literal=username="$GRAFANA_CLOUD_LOKI_USERNAME" \
  --from-literal=password="$GRAFANA_CLOUD_ACCESS_POLICY_TOKEN" \
  --dry-run=client -o yaml | kubectl apply -f -
```

Add the Grafana Helm repository and install the pinned Kubernetes Monitoring chart:

```shell
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update grafana

helm upgrade --install k8s-monitoring grafana/k8s-monitoring \
  --version 4.4.0 \
  --namespace monitoring \
  --wait --timeout 5m \
  -f values.yaml
```

## Prove that the exporters were reused

All three releases should be `deployed`:

```shell
helm list --namespace monitoring
```

There should be exactly one kube-state-metrics Deployment, owned by `ksm`, and exactly one Node Exporter DaemonSet, owned by `nodeexporter`:

```shell
kubectl get deployment -n monitoring \
  -l 'app.kubernetes.io/name=kube-state-metrics,app.kubernetes.io/instance=ksm'
kubectl get deployment -n monitoring \
  -l 'app.kubernetes.io/name=kube-state-metrics' -o name | wc -l

kubectl get daemonset -n monitoring \
  -l 'app.kubernetes.io/name=prometheus-node-exporter,app.kubernetes.io/instance=nodeexporter'
kubectl get daemonset -n monitoring \
  -l 'app.kubernetes.io/name=prometheus-node-exporter' -o name | wc -l
```

Both count commands should print `1`. This query should return no resources, proving that the `k8s-monitoring` release did not create either exporter workload:

```shell
kubectl get deployment,daemonset -n monitoring \
  -l 'app.kubernetes.io/instance=k8s-monitoring,app.kubernetes.io/name in (kube-state-metrics,prometheus-node-exporter)'
```

Check that both Alloy custom resources, the StatefulSet metrics collector, and the DaemonSet pod-logs collector are ready:

```shell
kubectl get alloy,pods -n monitoring
kubectl get statefulset,daemonset -n monitoring
```

Inspect the metrics collector logs for scrape, authentication, or remote-write failures:

```shell
kubectl logs -n monitoring statefulset/k8s-monitoring-alloy-metrics \
  --all-containers=true --since=10m | grep -Ei 'error|failed|401|403|remote.?write|scrape'

kubectl logs -n monitoring daemonset/k8s-monitoring-alloy-logs \
  --all-containers=true --since=10m | grep -Ei 'error|failed|401|403|loki|tail'
```

No repeated errors should appear. A small number of startup messages can be harmless; use the timestamps and repetition to distinguish them from an ongoing failure.

## Verify metrics in Grafana Cloud

Wait at least two scrape intervals (the chart default is 60 seconds), open **Explore** in Grafana Cloud, select the Prometheus data source, and run:

```promql
up{cluster="existing-exporters-demo", job="integrations/kubernetes/kube-state-metrics"}
```

```promql
kube_node_info{cluster="existing-exporters-demo"}
```

```promql
up{cluster="existing-exporters-demo", job="integrations/node_exporter"}
```

```promql
node_uname_info{cluster="existing-exporters-demo"}
```

Both `up` queries should return `1`; the other queries should return the kind control-plane node.

To verify pod logs, select the Loki data source in Explore and run:

```logql
{cluster="existing-exporters-demo"}
```

The query should return logs from pods in the kind cluster, with labels including `namespace`, `pod`, and `container`.

## Troubleshooting

### Helm reports that it is unable to find exporter pods

Chart 4.4.0 validates external exporter selectors against live pods during installation. Re-run the two selector-specific `kubectl get pods` commands above. If either returns nothing, check the namespace, pod readiness, release name, and labels. Keep the matchers in `values.yaml` aligned with the actual pods.

### Alloy reports HTTP 401 or 403

A `401` usually means a destination username or token is wrong. A `403` usually means the access policy lacks permission. Confirm that each username is the corresponding Grafana Cloud Prometheus or Loki instance ID, the token has both publisher scopes, and both URLs belong to the same stack. After correcting `.env`, rerun both idempotent Secret commands and the `helm upgrade --install` command.

### Metrics or pod logs do not appear immediately

Wait at least two 60-second scrape intervals, widen Explore's time range, and retry the metrics or logs query. If the selector checks succeed but metrics are still absent, inspect the metrics Alloy logs for scrape and remote-write errors. If pod logs are absent, confirm `k8s-monitoring-alloy-logs` is Ready on every node and inspect its logs for file-tail or Loki write errors. In either data source, confirm the query uses `cluster="existing-exporters-demo"`.

## Tear down

Deleting the kind cluster removes all three releases, both Secrets, and their data-plane resources:

```shell
kind delete cluster --name existing-exporters-demo
```
