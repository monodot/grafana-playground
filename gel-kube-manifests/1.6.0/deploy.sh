#!/bin/sh

if [ -z $1 ] || [ -z $2 ]; then
    echo "Usage: $0 [namespace] [path/to/license.jwt]"
    exit 1
fi

namespace=$1

# If license.jwt doesn't exist, bail out.
if [ ! -f $2 ]; then
    echo "license.jwt not found. Bailing out."
    exit 1
fi

echo "Deploying Minio and GEL..."
kubectl -n $namespace create secret generic ge-logs-license --from-file $2
kubectl -n $namespace apply -f minio.yaml
kubectl -n $namespace apply -f services.yaml
kubectl -n $namespace apply -f statefulset.yaml
kubectl -n $namespace apply -f compactor.yaml
kubectl -n $namespace apply -f configmap.yaml
echo "Done."

echo "Waiting for the first GEL pod to be ready..."
kubectl wait -n $namespace pod/ge-logs-0 --for condition=Ready --timeout=1h
echo "Done."

kubectl -n $namespace apply -f tokengen-job.yaml

echo "Waiting for the tokengen job to complete..."
kubectl -n $namespace wait job/ge-logs-tokengen --for condition=complete
echo "Done!"

echo "---"
echo "GEL is now available."
echo "You can access the API by port-forwarding to the GEL pod, e.g.:"
echo "kubectl -n $namespace port-forward ge-logs-0 3100:3100"
echo "Set the API token in your environment:"
echo "GEL_TOKEN=$(kubectl -n $namespace logs job/ge-logs-tokengen | tail -n 1 | awk '{print $2}')"
echo "Then you can call the API, e.g.:"
echo "curl localhost:3100/ready"
echo 'curl -u :$GEL_TOKEN localhost:3100/admin/api/v3/tenants'
echo ''
echo 'Live, laugh, log.'
