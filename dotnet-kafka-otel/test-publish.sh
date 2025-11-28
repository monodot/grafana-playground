#!/bin/bash
# Script to produce test messages to the purchases topic

echo "Producing test messages to the 'purchases' topic..."

# Produce 10 test messages
for i in {1..10}; do
  MESSAGE="order-$i:{\"orderId\":\"$i\",\"product\":\"item-$i\",\"quantity\":$((RANDOM % 10 + 1)),\"price\":$((RANDOM % 100 + 10))}"
  
  echo "$MESSAGE" | docker compose exec -T broker /opt/kafka/bin/kafka-console-producer.sh \
    --bootstrap-server broker:9092 \
    --topic purchases \
    --property "parse.key=true" \
    --property "key.separator=:"
  
  echo "Sent message $i: $MESSAGE"
  sleep 1
done

echo "Done! All test messages sent."
