#!/bin/bash

# Get ECS service ARN
SERVICE_ARN=$(aws ecs describe-services \
  --cluster $ECS_CLUSTER_NAME \
  --services $ECS_SERVICE_NAME \
  --query 'services[0].serviceArn' \
  --output text)

aws ecs list-tags-for-resource \
  --resource-arn $SERVICE_ARN \
  --query 'tags' \
  --output json | \
jq -r 'map("    \"set(resource.attributes[\\\"custom." + (.key | ascii_downcase) + "\\\"], \\\"" + .value + "\\\")\",") | join("\n")' > /tmp/trace_statements.txt


echo "Generated trace statements:"
cat /tmp/trace_statements.txt

# Replace the placeholder with the generated content
sed -i '/\/\/ CUSTOM_TRACE_STATEMENTS/r /tmp/trace_statements.txt' /etc/alloy/config.alloy
sed -i '/\/\/ CUSTOM_TRACE_STATEMENTS/d' /etc/alloy/config.alloy

echo "Config processed successfully"

# Optional: Show the final config
echo "=== Final config ==="
cat /etc/alloy/config.alloy
