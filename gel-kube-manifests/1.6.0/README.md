# Grafana Enterprise Logs 1.6.0 on Kubernetes deployed with manifests

You will need a Kubernetes cluster for this.

## Deploy

1. Create a namespace for Grafana Enterprise Logs:

```bash
kubectl create namespace grafana-enterprise-logs
```

2. Download your license file, ensure it's named `license.jwt` and place it in the current directory.

3. Deploy Grafana Enterprise Logs:

```bash
./deploy.sh [namespace]
```

## Delete

```bash
./clean.sh [namespace]
```

