# Grafana Enterprise Logs 1.6.0 + Minio on Kubernetes

This quick demo deploys Grafana Enterprise Logs 1.6.0 with Minio storage backend on Kubernetes.

You will need a Kubernetes cluster for this.

## Deploy

1. Edit the file `configmap.yaml` to set your GEL cluster name (as given in your license key), e.g. `cluster_name: tomdonohuegel`

2. Download your license file.

3. Deploy Grafana Enterprise Logs:

```bash
./deploy.sh [namespace] [path-to-license-file]
```

## Delete

```bash
./clean.sh [namespace]
```

