# Alloy on GKE with Helm

A demo that deploys [Alloy](https://grafana.com/docs/alloy/latest/) via Helm on GKE, with sample workloads, sending metrics and traces to Grafana Cloud.

## Set up

### Create a cluster

Log in to GCP and select a project:

```shell
gcloud auth login

gcloud config set project PROJECT_ID
```

Create a GKE cluster:

```shell
gcloud container clusters create alloy-helm-demo \
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

### Install Alloy

Add the Grafana Helm repo if you haven't already:

```shell
helm repo add grafana https://grafana.github.io/helm-charts

helm repo update
```

Fetch the cluster credentials:

```shell
gcloud container clusters get-credentials alloy-helm-demo --zone us-central1-a
```

Load the variables into your shell and install Alloy, substituting your env vars into `values.yaml`:

```shell
set -a && source .env && set +a

envsubst < values/beyla-simple.yaml | helm upgrade --install alloy grafana/alloy --namespace alloy --create-namespace -f -
```

Verify it's running:

```shell
kubectl get pods --namespace alloy
```

### Deploy test workloads

Deploy `http-echo` (the instrumented service) and a k6 load generator that hits it every second:

```shell
kubectl apply -f manifests/
```

## Tear down

Uninstall the workloads and Alloy:

```shell
kubectl delete -f manifests/

helm uninstall alloy -n alloy
```

Destroy the cluster completely:

```shell
gcloud container clusters delete alloy-helm-demo --zone us-central1-a
```

## Notes

- k6 -> node-server has context propagated. But node-server -> http-echo does not.
