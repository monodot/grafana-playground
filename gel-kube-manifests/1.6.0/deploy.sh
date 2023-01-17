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

kubectl -n $namespace create secret generic ge-logs-license --from-file $2

echo "Creating the GEL objects..."
kubectl -n $namespace apply -f services.yaml
kubectl -n $namespace apply -f statefulset.yaml
kubectl -n $namespace apply -f compactor.yaml
kubectl -n $namespace apply -f configmap.yaml
echo "Done."

echo "Waiting for the GEL compactor to be ready..."
kubectl wait -n $namespace deploy/compactor --for condition=available --timeout=1h
echo "Done."

kubectl apply -f tokengen-job.yaml
echo "Waiting for the tokengen job to complete..."
kubectl -n $namespace wait job/tokengen --for condition=complete

echo "Done!"
echo "GEL is now available at: https://$(kubectl -n $namespace get svc gel -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"
