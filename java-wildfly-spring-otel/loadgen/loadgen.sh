#!/bin/sh
# Sends a steady trickle of orders to the gateway API, with the demo headers
# (X-Customer-Id, X-User-Id, Authorization) that the OTel agent captures onto spans.
# Customer IDs ending in 7 trigger the gateway's simulated fraud check, so ~10% of
# requests produce error traces.

GATEWAY_URL="${GATEWAY_URL:-http://gateway-api:8080}"
TOMCAT_URL="${TOMCAT_URL:-http://legacy-tomcat:8080}"

i=0
while true; do
  i=$((i + 1))
  cust=$(printf 'CUST-%04d' $(( (i % 50) + 1 )))

  case $((i % 5)) in
    0) item="anvil" ;;
    1) item="rocket-skates" ;;
    2) item="giant-magnet" ;;
    3) item="bird-seed" ;;
    4) item="portable-hole" ;;
  esac

  curl -s -o /dev/null -w "POST /orders $cust -> %{http_code}\n" \
    -X POST "$GATEWAY_URL/orders" \
    -H "Content-Type: application/json" \
    -H "X-Customer-Id: $cust" \
    -H "X-User-Id: doris.demo" \
    -H "Authorization: Bearer demo-token-not-a-real-secret" \
    -d "{\"customerId\":\"$cust\",\"item\":\"$item\",\"quantity\":$(( (i % 3) + 1 ))}"

  if [ $((i % 5)) -eq 0 ]; then
    curl -s -o /dev/null -w "GET /orders/summary -> %{http_code}\n" \
      -H "X-User-Id: doris.demo" \
      "$GATEWAY_URL/orders/summary"
  fi

  # The Tomcat legacy app: 'emea' and 'apac' are registered regions, everything
  # else fails with a nested routing exception mapped to a 500.
  case $((i % 3)) in
    0) region="emea" ;;
    1) region="apac" ;;
    2) region="latam" ;;
  esac
  curl -s -o /dev/null -w "GET /accounts ($region) -> %{http_code}\n" \
    -H "X-User-Id: doris.demo" \
    -H "Authorization: Bearer demo-token-not-a-real-secret" \
    "$TOMCAT_URL/legacy-tomcat/api/customers/$region/accounts"

  sleep 3
done
