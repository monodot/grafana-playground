# Kubernetes (k3s) variant, sending directly to Grafana Cloud

Deploys the same applications as the compose demo onto a local single-node k3s cluster, with every service sending its telemetry **directly to the Grafana Cloud OTLP gateway** — no local Grafana stack and no collector in between. This simulates applications instrumented straight against Grafana Cloud.

Differences from the compose variant:

- No `otel-lgtm` container: traces, metrics and logs go to your Grafana Cloud stack. The gateway's continuous profiles go to Grafana Cloud Profiles.
- The schema setup runs as a Kubernetes Job instead of a one-shot container.
- Oracle keeps its data on a PersistentVolumeClaim (k3s `local-path` storage).
- Resource attributes add `deployment.environment=demo-k8s` and a `service.instance.id` from the pod name, so you can tell the k8s pods apart from the compose containers in Grafana.

All cluster commands below use `sudo k3s kubectl`, which talks directly to the local k3s cluster and ignores your `~/.kube/config` (and whatever context it currently points at).

## Prerequisites

- A local [k3s](https://k3s.io/) cluster (single node is fine) and sudo access.
- Podman, to build the demo images.
- A Grafana Cloud stack, with:
  - the **OTLP endpoint** and **instance ID** from your stack's *OpenTelemetry* connection page (Grafana Cloud portal → your stack → Configure → OpenTelemetry),
  - the **Pyroscope URL** and **user ID** from the *Profiles* connection page,
  - an access policy **token** with `metrics:write`, `logs:write`, `traces:write` and `profiles:write` scopes.

## 1. Build and import the images

k3s runs its own containerd, so podman-built images must be imported once (and again after any image change):

```bash
./k8s/import-images.sh
```

## 2. Create the credentials Secret

Nothing sensitive is committed; the manifests read everything from one Secret that you create. The OTLP headers value is `Authorization=Basic <credentials>`, where `<credentials>` is the base64 of `instanceID:token`:

```bash
sudo k3s kubectl create namespace orders-demo

OTLP_CREDS=$(echo -n "<instance ID>:<token>" | base64 -w0)

sudo k3s kubectl -n orders-demo create secret generic grafana-cloud \
  --from-literal=otlp-endpoint="https://otlp-gateway-<region>.grafana.net/otlp" \
  --from-literal=otlp-headers="Authorization=Basic ${OTLP_CREDS}" \
  --from-literal=pyroscope-url="https://profiles-prod-<nnn>.grafana.net" \
  --from-literal=pyroscope-user="<pyroscope user ID>" \
  --from-literal=pyroscope-password="<token>"
```

## 3. Deploy

The kustomization lives at the demo root (so it can reuse the SQL and loadgen script shared with the compose variant):

```bash
sudo k3s kubectl apply -k .
```

Oracle takes a few minutes on first start because the database files are created on the PersistentVolume. The `oracle-init` Job retries until the database is ready, then applies the schema and completes.

## 4. Verify

```bash
sudo k3s kubectl -n orders-demo get pods
# oracle-init should reach Completed; everything else Running

sudo k3s kubectl -n orders-demo logs deploy/loadgen --tail=5
# POST /orders CUST-00xx -> 200  (and -> 500 for customer IDs ending in 7)

sudo k3s kubectl -n orders-demo logs deploy/batch-job | grep Exporting
# "Exporting 5 pending orders" once per minute
```

Then in your Grafana Cloud stack:

- **Traces**: query TraceQL `{ span.db.system = "oracle" }` or `{ status = error }`. Traces span batch-job → gateway-api → legacy-wildfly → Oracle, with the captured `http.request.header.x-customer-id` attributes. The `legacy-tomcat` error traces carry the nested routing exception as a span event: `{ event.exception.type =~ ".*PlatformFaultException" }`.
- **Profiles**: the `gateway-api` service shows CPU flame graphs, and its spans link to profiles.
- **Node metrics**: not collected by this demo. If the cluster runs Grafana's Kubernetes Monitoring Helm chart (as the development machine for this demo does), node-level CPU and memory are already in your stack, and that is the recommended way to add them.

The dashboard from the compose variant (`../provisioning/dashboards/orders-overview.json`) can be imported into Grafana Cloud manually — re-select your Prometheus datasource on import. The span-metrics panels require span metrics generation to be enabled on your stack.

## Cleanup

```bash
sudo k3s kubectl delete -k .
```

Deleting the namespace removes the PVC and the Oracle data with it.
