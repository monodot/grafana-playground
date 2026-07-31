---
keywords: [opentelemetry-operator, kind, java, spring-boot, auto-instrumentation, instrumentation-cr, otel-lgtm, traces, kubernetes]
---

# OpenTelemetry Operator on kind, with Java auto-instrumentation

A fully ephemeral demo that runs the OpenTelemetry Operator on a local kind cluster, auto-instruments a Spring Boot app with the Java agent, and ships traces, metrics and logs to a `grafana/otel-lgtm` instance running in the same cluster.

Everything runs inside the kind cluster, so there is nothing to clean up other than deleting the cluster.

The demo also shows how to pass extra Java agent settings through the `Instrumentation` resource. It sets `OTEL_INSTRUMENTATION_COMMON_EXPERIMENTAL_CONTROLLER_TELEMETRY_ENABLED=true`, which makes the agent emit an extra span for the Spring MVC controller method that handles each request.

## What gets deployed

| Namespace | Workload | Description |
|---|---|---|
| `observability` | `otel-lgtm` | Grafana, Loki, Tempo and Prometheus in one pod, with an OTLP endpoint |
| `demo-app` | `order-api` | A Spring Boot app with a couple of REST endpoints |
| `demo-app` | `loadgen` | k6, hitting `order-api` once a second |
| `demo-app` | `java-instrumentation` | The `Instrumentation` resource that configures the Java agent |

## Prerequisites

- `kind`
- `kubectl`
- Podman or Docker

If you use Podman, export this before running any `kind` command:

```shell
export KIND_EXPERIMENTAL_PROVIDER=podman
```

## Set up

### Create the cluster

```shell
kind create cluster --config kind-cluster.yaml
```

The cluster config maps container port 30000 to `localhost:3000`, so you can reach Grafana in your browser without a port-forward.

### Install cert-manager

The OpenTelemetry Operator needs cert-manager for its admission webhook certificates:

```shell
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.20.0/cert-manager.yaml

kubectl wait --for=condition=Available deployment --all -n cert-manager --timeout=180s
```

### Install the OpenTelemetry Operator

```shell
kubectl apply -f https://github.com/open-telemetry/opentelemetry-operator/releases/latest/download/opentelemetry-operator.yaml

kubectl wait --for=condition=Available deployment --all -n opentelemetry-operator-system --timeout=240s
```

### Build the Java app and load it into the cluster

The app is a small Spring Boot service. Build it, then load the image into the kind node so that Kubernetes doesn't try to pull it from a registry:

```shell
podman build -t localhost/order-api:1.0.0 ./app

kind load docker-image localhost/order-api:1.0.0 --name otel-operator-demo
```

### Deploy everything

```shell
kubectl apply -f manifests/
```

Wait for the stack to start. The `otel-lgtm` pod takes about a minute:

```shell
kubectl wait --for=condition=Ready pod -l app=otel-lgtm -n observability --timeout=300s

kubectl wait --for=condition=Ready pod -l app=order-api -n demo-app --timeout=300s
```

## How the instrumentation works

The `order-api` deployment carries a single annotation:

```yaml
annotations:
  instrumentation.opentelemetry.io/inject-java: "true"
```

When you create that pod, the operator's mutating webhook rewrites the pod spec. It adds an init container that copies the OpenTelemetry Java agent into a shared volume, mounts that volume into the app container, and sets `JAVA_TOOL_OPTIONS` to `-javaagent:/otel-auto-instrumentation-java-order-api/javaagent.jar`. The app itself needs no changes.

The operator reads the settings for the agent from the `Instrumentation` resource in the same namespace:

```yaml
apiVersion: opentelemetry.io/v1alpha1
kind: Instrumentation
metadata:
  name: java-instrumentation
  namespace: demo-app
spec:
  exporter:
    endpoint: http://otel-lgtm.observability.svc.cluster.local:4317
  java:
    env:
      - name: OTEL_INSTRUMENTATION_COMMON_EXPERIMENTAL_CONTROLLER_TELEMETRY_ENABLED
        value: "true"
      - name: DORIS_WAS_HERE
        value: "hello-from-the-instrumentation-cr"
```

Anything under `spec.java.env` becomes an environment variable on the app container. This is how you configure the agent without touching the application's own deployment manifest.

### Proving that the variables get through

`DORIS_WAS_HERE` is in the `Instrumentation` resource purely as a test. Nothing reads it, and it appears nowhere in `manifests/30-order-api.yaml`. If you can see it inside the running container, the only way it got there is the operator's webhook.

Read the environment out of the running process:

```shell
kubectl exec -n demo-app deploy/order-api -c order-api -- env | sort | grep -E 'DORIS_WAS_HERE|CONTROLLER_TELEMETRY|JAVA_TOOL_OPTIONS'
```

```
DORIS_WAS_HERE=hello-from-the-instrumentation-cr
JAVA_TOOL_OPTIONS= -javaagent:/otel-auto-instrumentation-java-order-api/javaagent.jar
OTEL_INSTRUMENTATION_COMMON_EXPERIMENTAL_CONTROLLER_TELEMETRY_ENABLED=true
```

The same variables are on the pod spec, next to the ones the operator adds itself, such as `OTEL_EXPORTER_OTLP_ENDPOINT` and `OTEL_RESOURCE_ATTRIBUTES`:

```shell
kubectl get pod -n demo-app -l app=order-api \
  -o jsonpath='{range .items[0].spec.containers[0].env[*]}{.name}={.value}{"\n"}{end}'
```

## View the traces

Open Grafana at <http://localhost:3000>. Log in as `admin` / `admin`, or use the anonymous access that the deployment enables.

Go to **Explore**, pick the **Tempo** datasource, and run a TraceQL query:

```traceql
{ resource.service.name = "order-api" }
```

Open a trace for `GET /orders/{id}/invoice`. Because controller telemetry is switched on, each trace has two spans instead of one:

- `GET /orders/{id}/invoice` — the server span, created by the Servlet instrumentation
- `OrderController.getInvoice` — an internal span for the controller method

Without `OTEL_INSTRUMENTATION_COMMON_EXPERIMENTAL_CONTROLLER_TELEMETRY_ENABLED`, only the server span appears.

### Compare with the setting turned off

Set the variable to `false` and restart the app:

```shell
kubectl patch instrumentation java-instrumentation -n demo-app \
  --type=json -p='[{"op":"replace","path":"/spec/java/env/0/value","value":"false"}]'

kubectl rollout restart deploy/order-api -n demo-app

kubectl rollout status deploy/order-api -n demo-app --timeout=300s
```

The operator only reads the `Instrumentation` resource when it creates a pod, so you have to restart the deployment for a change to take effect. New traces now have one span instead of two.

Give it a minute or two before you judge the result. The old pod flushes its last batch of spans as it shuts down, so for a short while Tempo returns a mix of one-span and two-span traces. If you want to be sure which pod produced a span, check its `k8s.pod.name` resource attribute against the pod that is running now:

```shell
kubectl get pods -n demo-app -l app=order-api
```

Set it back to `true` the same way:

```shell
kubectl patch instrumentation java-instrumentation -n demo-app \
  --type=json -p='[{"op":"replace","path":"/spec/java/env/0/value","value":"true"}]'

kubectl rollout restart deploy/order-api -n demo-app
```

## Tear down

Delete the cluster. This removes the operator, cert-manager, the workloads and all telemetry in one go:

```shell
kind delete cluster --name otel-operator-demo
```
