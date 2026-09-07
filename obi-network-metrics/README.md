# OpenTelemetry eBPF Instrumentation network metrics demo

This demo uses OpenTelemetry eBPF Instrumentation (OBI) to measure network
traffic between Kubernetes workloads.

In this demo, a small Envoy gateway forwards requests to a catalog service, which serves a 7 MiB test image. OBI records the resulting traffic without requiring changes to either application.

You can run the demo in either of two environments:

- **Amazon EKS** demonstrates both network flow metrics and traffic between
  Availability Zones (AZs). This option creates chargeable AWS resources.
- **kind** runs entirely on your local machine. It demonstrates network flow
  metrics, but its single node setup can't simulate inter-zone traffic.

**NB:** Run all commands from the root of this repository.

## Requirements

Both versions require:

- [Docker](https://docs.docker.com/engine/install/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Helm](https://helm.sh/docs/intro/install/)
- `curl`

The EKS version also requires:

- An AWS account with permission to create EKS and ECR resources
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- [eksctl](https://eksctl.io/installation/)

The local version also requires [kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation).

## Option 1: Run the demo on Amazon EKS

This version creates a three-node EKS cluster across `us-east-1a`, `us-east-1b`, and `us-east-1d`. The gateway and catalog are placed in different AZs so that requests between them produce inter-zone metrics.

### 1. Authenticate with AWS

Set the name of a configured AWS CLI profile, sign in, and verify the active identity:

```shell
export AWS_PROFILE=your-profile
aws sso login --profile "$AWS_PROFILE"
aws sts get-caller-identity
```

If your profile uses long-lived credentials rather than IAM Identity Center, skip the `aws sso login` command.

### 2. Create the EKS cluster

```shell
eksctl create cluster --config-file obi-network-metrics/eksctl-cluster.yaml
```

Cluster creation usually takes 15–20 minutes. When it finishes, select its kubectl context and confirm that the nodes span the three configured AZs:

```shell
aws eks update-kubeconfig \
  --name obi-network-metrics-demo \
  --region us-east-1

kubectl get nodes -L topology.kubernetes.io/zone
```

Don't continue unless there is a Ready node **in both `us-east-1a` and `us-east-1b`**. The placement commands below depend on those zones.

### 3. Build and push the catalog image

Set the image variables:

```shell
REGION=us-east-1
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REPOSITORY=obi-network-metrics/catalog
REGISTRY="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"
TAG=$(git rev-parse --short HEAD)
```

Create the ECR repository. You only need to do this the first time you run the
demo:

```shell
aws ecr create-repository \
  --region "$REGION" \
  --repository-name "$REPOSITORY"
```

Authenticate Docker, then build and push an image for the EKS nodes' AMD64
architecture:

```shell
aws ecr get-login-password --region "$REGION" | \
  docker login --username AWS --password-stdin "$REGISTRY"

docker build \
  --platform linux/amd64 \
  --tag "$REGISTRY/$REPOSITORY:$TAG" \
  obi-network-metrics/catalog

docker push "$REGISTRY/$REPOSITORY:$TAG"
```

### 4. Deploy the demo applications

Apply the EKS manifests, set the catalog image, and pin the two application
deployments to different AZs:

```shell
kubectl apply -k obi-network-metrics/deploy/eks

kubectl --namespace obi-network-metrics set image \
  deployment/catalog \
  catalog="$REGISTRY/$REPOSITORY:$TAG"

# Pin the gateway to us-east-1a
kubectl --namespace obi-network-metrics patch deployment shopfront-gateway \
  --type merge \
  --patch '{"spec":{"template":{"spec":{"nodeSelector":{"topology.kubernetes.io/zone":"us-east-1a"}}}}}'

# Pin the catalog service to us-east-1b - oooh, this'll be expensive!
kubectl --namespace obi-network-metrics patch deployment catalog \
  --type merge \
  --patch '{"spec":{"template":{"spec":{"nodeSelector":{"topology.kubernetes.io/zone":"us-east-1b"}}}}}'
```

Wait for the applications to become ready:

```shell
kubectl rollout status deployment/catalog --namespace obi-network-metrics
kubectl rollout status deployment/shopfront-gateway --namespace obi-network-metrics
kubectl rollout status deployment/grafana-otel-lgtm --namespace obi-network-metrics
```

Verify the placement of the Pods, by matching each application's node to the node's zone. The `catalog` and `shopfront-gateway` Pods should be on nodes in different zones:

```shell
kubectl get pods --namespace obi-network-metrics \
  --selector app.kubernetes.io/part-of=obi-network-metrics-demo \
  --output custom-columns=NAME:.metadata.name,NODE:.spec.nodeName

kubectl get nodes -L topology.kubernetes.io/zone
```

### 5. Deploy OBI

Add the OpenTelemetry chart repository and install OBI as a DaemonSet:

```shell
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm repo update open-telemetry

helm upgrade --install obi open-telemetry/opentelemetry-ebpf-instrumentation \
  --version 0.13.0 \
  --namespace obi-network-metrics \
  --values obi-network-metrics/obi-values.yaml \
  --wait \
  --timeout 5m

kubectl rollout status daemonset/obi --namespace obi-network-metrics
```

The values file enables the metric `obi.network.flow.bytes` and the experimental `obi.network.inter.zone.bytes` metric, adds Kubernetes workload metadata, and sends the metrics to the in-cluster OpenTelemetry backend in-a-box (`otel-lgtm`).

### 6. Generate traffic

In one terminal, forward a local port to the gateway:

```shell
kubectl port-forward \
  --namespace obi-network-metrics \
  service/shopfront-gateway 8080:8080
```

In a second terminal, verify the API and request the 7 MiB test image 20 times:

```shell
curl http://localhost:8080/api/products

for request in $(seq 1 20); do
  curl --silent --show-error --output /dev/null \
    http://localhost:8080/images/products/egg-sandwich.jpg
done
```

These requests travel from the gateway in `us-east-1a` to the catalog in `us-east-1b`.

### 7. View the metrics

In a third terminal, forward Grafana's port:

```shell
kubectl port-forward \
  --namespace obi-network-metrics \
  service/grafana-otel-lgtm 3000:3000
```

Open <http://localhost:3000>, select **Drilldown > Metrics**, and search for:

- `obi.network.flow.bytes`
- `obi.network.inter.zone.bytes`

Allow a minute for newly generated metrics to appear.

### 8. Delete the EKS resources

Delete the cluster when you finish to stop incurring EKS and EC2 charges:

```shell
eksctl delete cluster \
  --config-file obi-network-metrics/eksctl-cluster.yaml \
  --wait
```

If you no longer need the demo images, also delete the ECR repository:

```shell
aws ecr delete-repository \
  --region us-east-1 \
  --repository-name obi-network-metrics/catalog \
  --force
```

## Option 2: Run the demo locally with kind

The kind version uses the same workloads and OBI configuration on one local node. It produces `obi.network.flow.bytes`.

`obi.network.inter.zone.bytes` won't contain any meaningful data here, because `kind`, since it's running locally, has no cloud AZ metadata or cross-zone traffic for OBI to aggregate.

### 1. Create the kind cluster

```shell
kind create cluster --config obi-network-metrics/kind-cluster.yaml
kubectl get nodes
```

### 2. Build and load the catalog image

```shell
docker build \
  --tag localhost/catalog-service:1.0.0 \
  obi-network-metrics/catalog

kind load docker-image \
  localhost/catalog-service:1.0.0 \
  --name obi-network-metrics-demo
```

### 3. Deploy the demo applications

The kind overlay exposes Grafana on <http://localhost:3000> through a NodePort:

```shell
kubectl apply -k obi-network-metrics/deploy/kind

kubectl rollout status deployment/catalog --namespace obi-network-metrics
kubectl rollout status deployment/shopfront-gateway --namespace obi-network-metrics
kubectl rollout status deployment/grafana-otel-lgtm --namespace obi-network-metrics
```

### 4. Deploy OBI

```shell
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm repo update open-telemetry

helm upgrade --install obi open-telemetry/opentelemetry-ebpf-instrumentation \
  --version 0.13.0 \
  --namespace obi-network-metrics \
  --values obi-network-metrics/obi-values.yaml \
  --wait \
  --timeout 5m

kubectl rollout status daemonset/obi --namespace obi-network-metrics
```

### 5. Generate traffic

In one terminal, forward a local port to the gateway:

```shell
kubectl port-forward \
  --namespace obi-network-metrics \
  service/shopfront-gateway 8080:8080
```

In a second terminal, verify the API and request the test image 20 times:

```shell
curl http://localhost:8080/api/products

for request in $(seq 1 20); do
  curl --silent --show-error --output /dev/null \
    http://localhost:8080/images/products/egg-sandwich.jpg
done
```

### 6. View the metrics

Open <http://localhost:3000>, select **Drilldown > Metrics**, and search for
`obi.network.flow.bytes`. Allow a minute for newly generated metrics to appear.

### 7. Delete the kind cluster

```shell
kind delete cluster --name obi-network-metrics-demo
```

## Alternative: send metrics directly to Grafana Cloud

By default, `obi-values.yaml` sends metrics to the Grafana OpenTelemetry LGTM service inside the cluster. To send them directly to Grafana Cloud instead, create a Kubernetes Secret containing your Grafana Cloud OTLP connection details:

```shell
set -a && source obi-network-metrics/.env && set +a

kubectl create secret generic grafana-cloud-otlp \
  --namespace obi-network-metrics \
  --from-literal=endpoint="$OTEL_EXPORTER_OTLP_ENDPOINT" \
  --from-literal=headers="$OTEL_EXPORTER_OTLP_HEADERS" \
  --dry-run=client \
  --output yaml | kubectl apply --filename -

#unset GRAFANA_CLOUD_API_KEY
```

Use a Grafana Cloud access policy token with the `metrics:write` scope. Copy the
OTLP instance ID from the OpenTelemetry card in your Grafana Cloud stack. The
cloud zone is the part of its endpoint between `otlp-gateway-` and
`.grafana.net`; for example, the zone for
`https://otlp-gateway-prod-eu-west-0.grafana.net/otlp` is
`prod-eu-west-0`.

Install OBI with both values files, with the Grafana Cloud file last:

```shell
helm upgrade --install obi open-telemetry/opentelemetry-ebpf-instrumentation \
  --version 0.13.0 \
  --namespace obi-network-metrics \
  --values obi-network-metrics/obi-values.yaml \
  --values obi-network-metrics/obi-values-grafana-cloud.yaml \
  --wait \
  --timeout 5m
```

With this configuration, view the metrics in your **Grafana Cloud stack** rather than the local Grafana instance. Grafana Cloud converts the OpenTelemetry metric names to Prometheus-compatible names, including `obi_network_flow_bytes_total` and `obi_network_inter_zone_bytes_total`. To return to the local LGTM exporter, run the original Helm command with only `obi-values.yaml`.

## Development and testing

Run the catalog service tests locally:

```shell
cd obi-network-metrics/catalog
GOCACHE=/tmp/obi-network-metrics-go-cache go test ./...
```

Run the catalog service locally on port 8080:

```shell
cd obi-network-metrics/catalog
go run .
```

## Possible ways to reduce inter-zone traffic

OBI identifies network traffic; it does not prescribe how to change the application. Depending on the system, ways to reduce inter-zone traffic could include:

- Serving static assets from a content delivery network (CDN)
- Caching large, frequently requested responses
- Using Kubernetes pod affinity to place services that exchange large amounts of data in the same zone
