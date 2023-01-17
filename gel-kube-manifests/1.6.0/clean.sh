#!/bin/sh

if [ -z $1 ]; then
    echo "Usage: $0 [namespace]"
    exit 1
fi

namespace=$1

kubectl -n $namespace delete secret ge-logs-license

echo "Deleting the GEL objects..."
kubectl -n $namespace delete -f services.yaml
kubectl -n $namespace delete -f statefulset.yaml
kubectl -n $namespace delete -f compactor.yaml
kubectl -n $namespace delete -f configmap.yaml
echo "Done!"


