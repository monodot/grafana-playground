# OpenTelemetry eBPF Instrumentation Network Metrics demo

Using OBI to observe network traffic between pods in an EKS cluster.

The purpose of this demo is to show:

- OBI can be used to expose exactly which interactions are generating the biggest network traffic, and between which availability zone(s)

Requirements:

- [kind](https://kind.sigs.k8s.io/)

## Set up

The cloud demo shows how OBI can record network traffic between Pods in an AWS EKS cluster.

It consists of this setup:

- An EKS cluster spanning three Availability Zones (AZs)
- A `shopfront-gateway` service in one zone, which terminates TLS, receives requests and routes requests to internal services, like the catalog service
- A `catalog` service in another zone, which renders product pages and serves images to the gateway
- A load testing service which generates traffic to the app

### Create the kind cluster (if using)

First create the kind cluster:

```shell
# kind create cluster --config obi-network-metrics/kind-cluster.yaml

mkdir -p "$HOME/.kube"
touch "$HOME/.kube/obi-kind"
sudo kind create cluster \
  --config obi-network-metrics/kind-cluster.yaml \
  --kubeconfig "$HOME/.kube/obi-kind"

sudo chown "$USER:$(id -gn)" "$HOME/.kube/obi-kind"

export KUBECONFIG="$HOME/.kube/obi-kind"
kubectl get nodes
```

Build and load the catalog service image into the cluster:

```shell
sudo docker build -t localhost/catalog-service:1.0.0 obi-network-metrics/catalog

sudo kind load docker-image localhost/catalog-service:1.0.0 --name obi-network-metrics-demo
```

### Deploy the apps

Deploy all the manifests:

```shell
kubectl create ns obi-network-metrics
```

```shell
kubectl apply -f obi-network-metrics/manifests/catalog.yaml -n obi-network-metrics
kubectl apply -f obi-network-metrics/manifests/shopfront-gateway.yaml -n obi-network-metrics
kubectl apply -f obi-network-metrics/manifests/grafana-otel-lgtm.yaml -n obi-network-metrics
kubectl rollout status deployment/catalog --namespace obi-network-metrics
kubectl rollout status deployment/shopfront-gateway --namespace obi-network-metrics
kubectl rollout status deployment/grafana-otel-lgtm --namespace obi-network-metrics
```

Deploy OBI as a DaemonSet. The values file enables flow-byte metrics and the
inter-zone metric, decorates them with Kubernetes ownership metadata, and sends
them directly to the in-cluster `grafana-otel-lgtm` OTLP/HTTP endpoint:

```shell
helm upgrade --install obi open-telemetry/opentelemetry-ebpf-instrumentation \
  --version 0.13.0 \
  --namespace obi-network-metrics \
  --values obi-network-metrics/obi-values.yaml \
  --wait --timeout 5m

kubectl rollout status daemonset/obi --namespace obi-network-metrics
```

The local Kind cluster has one node and no AWS Availability Zone metadata, so
it can demonstrate `obi.network.flow.bytes` but not a non-zero inter-zone
series. The same configuration produces `obi.network.inter.zone.bytes` when
run on EKS nodes in different AZs.

## Simulate traffic and see metrics

### Make a test request to the app

Verify the deployed gateway with a port-forward. Requests through this service
are forwarded to the catalog Service, creating the gateway-to-catalog network
flow that OBI will later observe:

```shell
kubectl port-forward --namespace obi-network-metrics service/shopfront-gateway 8080:8080
```

Then in another terminal:

```shell
curl http://localhost:8080/api/products
curl --output /dev/null --write-out '%{http_code} %{size_download} bytes\n' \
  http://localhost:8080/images/products/egg-sandwich.jpg
```

### Access OBI's network metrics in Grafana

Access Grafana at http://localhost:3000

Access Drilldown > Metrics.


## Tear down

Delete the kind cluster:

```shell
sudo kind delete cluster --name obi-network-metrics-demo
```

## Development/testing

Validate the catalog service locally:

```shell
cd obi-network-metrics/catalog
GOCACHE=/tmp/obi-network-metrics-go-cache go test ./...
```

Run the catalog service, it will listen by default on port 8080:

```shell
cd obi-network-metrics/catalog
go run .
```

## Wrapping up

OBI obviously doesn't prescribe a solution, it only gathers the metrics so you can see what's going on. Some possible solutions could be:

- host your static assets on a suitable service like CloudFlare
- configure some sort of cache so that the gateway doesn't repeatedly download the same large files/pages
- set Pod affinity, so that tightly-coupled services which tend to talk a lot, are always scheduled together on the same node
