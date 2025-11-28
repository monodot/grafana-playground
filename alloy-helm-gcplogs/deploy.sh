#!/usr/bin/env bash

# helm template --version 2.0.16 --atomic --timeout 300s myfoo grafana/k8s-monitoring \
#     --namespace myfoo --create-namespace -f values.yaml > rendered.yaml

helm template myalloy grafana/alloy --namespace myalloy --create-namespace -f values.yaml > rendered.yaml

kubectl create ns myalloy || true

kubectl -n myalloy apply -f rendered.yaml

kubectl -n myalloy create secret generic gcp-logs --from-file=key.json=key.json

