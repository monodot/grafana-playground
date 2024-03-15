# mock logs

Deploy a stacktrace generator:

```
kubectl create configmap scripts --from-file=scripts --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f stacktrace.yaml
```