#!/bin/bash

# Ensure the container cleanly exits on Ctrl+C
trap 'exit 0' SIGTERM SIGINT

while true; do
  TIMESTAMP=$(date +%s%N)
  curl -s -X POST http://alloy:4318/v1/logs \
    -H "Content-Type: application/json" \
    -d "{
      \"resourceLogs\": [{
        \"resource\": {
          \"attributes\": [{
            \"key\": \"service.name\",
            \"value\": {\"stringValue\": \"example-service\"}
          }, {
            \"key\": \"service.version\",
            \"value\": {\"stringValue\": \"1.0.0\"}
          }]
        },
        \"scopeLogs\": [{
          \"scope\": {
            \"name\": \"example-logger\",
            \"version\": \"1.0.0\"
          },
          \"logRecords\": [{
            \"timeUnixNano\": \"$TIMESTAMP\",
            \"observedTimeUnixNano\": \"$TIMESTAMP\",
            \"severityNumber\": 9,
            \"severityText\": \"INFO\",
            \"body\": {
              \"stringValue\": \"User login successful\"
            },
            \"attributes\": [{
              \"key\": \"user.id\",
              \"value\": {\"stringValue\": \"user123\"}
            }, {
              \"key\": \"http.method\",
              \"value\": {\"stringValue\": \"POST\"}
            }, {
              \"key\": \"http.status_code\",
              \"value\": {\"intValue\": \"200\"}
            }, {
              \"key\": \"custom.unwanted_attribute\",
              \"value\": {\"stringValue\": \"cats\"}
            }, {
              \"key\": \"custom.planet\",
              \"value\": {\"stringValue\": \"saturn\"}
            }, {
              \"key\": \"custom.foo\",
              \"value\": {\"stringValue\": \"bar\"}
            }, {
              \"key\": \"custom.colour\",
              \"value\": {\"stringValue\": \"red\"}
            }, {
              \"key\": \"custom.pet\",
              \"value\": {\"stringValue\": \"fido\"}
            }],
            \"traceId\": \"5b8aa5a2d2c872e8321cf37308d69df2\",
            \"spanId\": \"051581bf3cb55c13\"
          }]
        }]
      }]
    }"
  echo "Sent a log"
  sleep 5
done
