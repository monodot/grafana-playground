#!/usr/bin/env bash
# Runs the k6 benchmark against all 11 Lambda configurations in sequence.
# Must be run from the repo root after `terraform apply` completes.
#
# Usage:
#   ./k6/run-all.sh

set -euo pipefail

TERRAFORM_DIR="$(dirname "$0")/../terraform"
K6_SCRIPT="$(dirname "$0")/benchmark.js"

mkdir -p "$(dirname "$0")/results"

configs=(
  "config_1_url:c1-baseline"
  "config_2_url:c2-sdk"
  "config_3_url:c3-direct"
  "config_4_url:c4-col-layer"
  "config_5_url:c5-ext-col"
  "config_6_url:c6-metrics"
  "config_7_url:c7-traces"
  "config_8_url:c8-128mb"
  "config_9_url:c9-1024mb"
  "config_10_url:c10-snapstart"
  "config_11_url:c11-direct-snap"
)

for entry in "${configs[@]}"; do
  output_key="${entry%%:*}"
  config_name="${entry##*:}"

  echo ""
  echo "▶ Running $config_name ..."
  url=$(terraform -chdir="$TERRAFORM_DIR" output -raw "$output_key")

  FUNCTION_URL="$url" CONFIG_NAME="$config_name" k6 run "$K6_SCRIPT"
done

echo ""
echo "All configs complete. Results written to k6/results/."
