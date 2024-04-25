#!/bin/sh

if [ -z $1 ]; then
    echo "Usage: $0 [namespace]"
    exit 1
fi

namespace=$1

echo "Deleting the GEL and Minio objects..."
kubectl -n $namespace delete secret ge-logs-license
kubectl -n $namespace delete -f statefulset.yaml
kubectl -n $namespace delete -f services.yaml
kubectl -n $namespace delete -f compactor.yaml
kubectl -n $namespace delete -f configmap.yaml
kubectl -n $namespace delete -f minio.yaml
kubectl -n $namespace delete -f tokengen-job.yaml
echo "Done!"


