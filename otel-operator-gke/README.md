# OpenTelemetry Operator on GKE

A demo that deploys the OpenTelemetry Operator on GKE, to instrument a couple of sample workloads (Go and Node.js), to ship metrics and distributed traces to Grafana Cloud.

## Set up

### Create a cluster

Log in to GCP and select a project:

```shell
gcloud auth login

gcloud config set project PROJECT_ID
```

Create a GKE cluster:

```shell
gcloud container clusters create otel-operator-demo \
  --zone us-central1-a \
  --num-nodes 3 \
  --machine-type e2-standard-2 \
  --labels owner=tdonohue
```

### Configure

Copy `.env.example` to `.env` and fill in your Grafana Cloud details:

```shell
cp .env.example .env
```

### Install OpenTelemetry Operator

Add the OpenTelemetry Helm repo if you haven't already:

```shell
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm repo update
```

Fetch the cluster credentials:

```shell
gcloud container clusters get-credentials otel-operator-demo --zone us-central1-a
```

Install cert-manager, which is a prerequisite for otel-operator:

```shell
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.20.0/cert-manager.yaml

kubectl wait --for=condition=Available deployment --all -n cert-manager --timeout=120s
```

Install OpenTelemetry Operator, and wait for it to finish:

```shell
kubectl apply -f https://github.com/open-telemetry/opentelemetry-operator/releases/latest/download/opentelemetry-operator.yaml

kubectl wait --for=condition=Available deployment --all -n opentelemetry-operator-system --timeout=120s
```

Enable the Go instrumentation feature flag:

```shell
kubectl patch deployment opentelemetry-operator-controller-manager \
    -n opentelemetry-operator-system \
    --type=json \
    -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--enable-go-instrumentation=true"}]'

kubectl rollout status deployment/opentelemetry-operator-controller-manager -n opentelemetry-operator-system
```

Load the variables into your shell and create an instance of the OpenTelemetry Collector:

```shell
set -a && source .env && set +a

envsubst < otelcol-instance.yaml | kubectl apply -f -
```

Install Node.js instrumentation:

```shell
kubectl apply -f instrumentation-default.yaml
```

### Deploy test workloads

Create an Instrumentation, deploy two services, node-server and http-echo, and a k6 load generator that hits the node-server every second:

```shell
kubectl apply -f manifests/
```

Restart services if you've modified them:

```shell
kubectl rollout restart deploy/k6 deploy/http-echo deploy/node-server
```

The OpenTelemetry Operator will automatically instrument the services, and ship traces to Grafana Cloud.

## Tear down

Uninstall the workloads:

```shell
kubectl delete -f manifests/
```

Uninstall the OpenTelemetry Operator, and cert-manager:

```shell
kubectl delete -f https://github.com/cert-manager/cert-manager/releases/download/v1.20.0/cert-manager.yaml

kubectl delete -f https://github.com/open-telemetry/opentelemetry-operator/releases/latest/download/opentelemetry-operator.yaml
```

Destroy the cluster completely:

```shell
gcloud container clusters delete otel-operator-demo --zone us-central1-a
```
