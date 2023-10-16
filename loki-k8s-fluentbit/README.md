# Kubernetes -> Fluent Bit -> Loki

This example shows how to deploy Fluent Bit with the Loki output plugin to send logs to Loki or Grafana Cloud Logs.

This will give log lines that look like this:

```
{
  "time": "2023-10-16T10:23:54.439690967Z",
  "stream": "stderr",
  "_p": "F",
  "log": "[2023/10/16 10:23:54] [ info] [input:tail:tail.0] inotify_fs_add(): inode=392785 watch_fd=14 name=/var/log/containers/fluent-bit-hpksp_fluent-bit_fluent-bit-f031dcc3c73198d6e9b0a5f43d0e95365f69f838c0021a7db3884c1b00a0b9a6.log"
}
```

...and with these Loki labels:

- container
- host
- job (set to `fluentbit`)
- namespace
- pod

## Steps

1. Create a namespace:

    ```bash
    kubectl create namespace fluent-bit
    ```

2. Add the Fluent Bit Helm repository:

    ```bash
    helm repo add fluent https://fluent.github.io/helm-charts
    ```

3. Create a secret to store your Loki endpoint details for Fluent Bit:

    ```bash
    kubectl create secret generic loki-auth -n fluent-bit \
        --from-literal=LOKI_HOSTNAME=logs-prod-eu-west-0.grafana.net \
        --from-literal=LOKI_PORT=443 \
        --from-literal=LOKI_USERNAME=123456 \
        --from-literal=LOKI_PASSWORD=eyJrI.....
    ```

4. Install Fluent Bit into your Kubernetes cluster:

    ```bash
    helm upgrade --install -n fluent-bit \
        -f values.yaml \
        --set envFrom[0].secretRef.name=loki-auth \
        fluent-bit fluent/fluent-bit 
    ```

5. Profit.


The end.

