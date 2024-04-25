# Grafana Enterprise Logs 1.6.0 + Minio on Kubernetes

This quick demo deploys Grafana Enterprise Logs 1.6.0 with Minio storage backend on Kubernetes, exposed publicly through an external LoadBalancer.

You will need a Kubernetes cluster for this.

## Important notes

- GEL needs a minimum of 2 replicas to run.

- This cluster may be **exposed at a public IP address** (depending on your cloud provider's exact LoadBalancer implementation).

## Deploy

1. Edit the file `configmap.yaml` to set your GEL cluster name (as given in your license key), e.g. `cluster_name: tomdonohuegel`

2. Download your license file.

3. Deploy Grafana Enterprise Logs:

```bash
./deploy.sh [namespace] [path-to-license-file]
```

4. Get the external IP address:

```bash
kubectl get svc ge-logs -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```


## Delete

```bash
./clean.sh [namespace]
```

## Tools

To get the Minio console:

```
kubectl -n $NAMESPACE port-forward $(kubectl get pod --selector app=minio -o name) 36485:36485
```

Then open http://localhost:36485 in your browser.
