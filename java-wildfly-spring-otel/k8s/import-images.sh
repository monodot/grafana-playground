#!/bin/sh
# Builds the demo images with podman and imports them into the local k3s
# cluster's containerd, so the Deployments (imagePullPolicy: Never) can use them.
# Requires sudo for `k3s ctr`.
set -eu

demo_dir=$(cd "$(dirname "$0")/.." && pwd)

echo "Building images with podman compose..."
(cd "$demo_dir" && podman compose build)

for img in gateway-api batch-job legacy-wildfly; do
  echo "Importing localhost/java-wildfly-spring-otel_${img}:latest into k3s..."
  podman save "localhost/java-wildfly-spring-otel_${img}:latest" | sudo k3s ctr images import -
done

echo "Done. Images in k3s:"
sudo k3s ctr images ls | grep java-wildfly-spring-otel | awk '{print $1}'
