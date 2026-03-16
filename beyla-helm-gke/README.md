# Beyla (OpenTelemetry eBPF Instrumentation) on GKE

A demo that deploys [Beyla](https://grafana.com/docs/beyla/latest/) via Helm on GKE, with a sample workload (http-echo), sending metrics and traces to Grafana Cloud.

## Set up

### Create a cluster

Log in to GCP and select a project:

```shell
gcloud auth login

gcloud config set project PROJECT_ID
```

Create a GKE cluster:

```shell
gcloud container clusters create beyla-helm-demo \
  --zone us-central1-a \
  --num-nodes 3 \
  --machine-type e2-standard-2 \
  --labels owner=tdonohue
```

Beyla uses eBPF and requires privileged access, so a Standard cluster is needed (not Autopilot).

### Configure

Copy `.env.example` to `.env` and fill in your Grafana Cloud details:

```shell
cp .env.example .env
```

### Install Beyla

Add the Grafana Helm repo if you haven't already:

```shell
helm repo add grafana https://grafana.github.io/helm-charts && helm repo update
```

Fetch the cluster credentials:

```shell
gcloud container clusters get-credentials beyla-helm-demo --zone us-central1-a
```

Load the variables into your shell and install Beyla, substituting your env vars into `values.yaml`:

```shell
set -a && source .env && set +a

envsubst < values.yaml | helm upgrade --install --atomic --timeout 300s beyla grafana/beyla --namespace beyla --create-namespace -f -
```

### Deploy test workloads

Deploy `http-echo` (the instrumented service) and a k6 load generator that hits it every second:

```shell
kubectl apply -f manifests/
```

Beyla will automatically detect the `http-echo` service and ship traces to Grafana Cloud.

## Tear down

```shell
gcloud container clusters delete beyla-helm-demo --zone us-central1-a
```
