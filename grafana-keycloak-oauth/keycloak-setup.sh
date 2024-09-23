#!/bin/bash

set -e

source .env

# Generate CLIENT_SECRET if not provided
if [ -z "$CLIENT_SECRET" ]; then
  CLIENT_SECRET=$(openssl rand -hex 20)
  echo "Generated CLIENT_SECRET: $CLIENT_SECRET"
fi

# Get admin token
get_admin_token() {
  curl -s -X POST http://localhost:8080/realms/master/protocol/openid-connect/token \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "username=$KEYCLOAK_ADMIN" \
    -d "password=$KEYCLOAK_ADMIN_PASSWORD" \
    -d "grant_type=password" \
    -d "client_id=admin-cli" | jq -r '.access_token'
}

ADMIN_TOKEN=$(get_admin_token)

# Create realm
curl -s -X POST http://localhost:8080/admin/realms \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"realm\":\"$REALM_NAME\", \"enabled\":true}"

# Create sample users
create_user() {
  local username=$1
  local password=$2
  local firstname=$3
  local lastname=$4

  curl -s -X POST http://localhost:8080/admin/realms/$REALM_NAME/users \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
      \"username\":\"$username\",
      \"enabled\":true,
      \"firstName\":\"$firstname\",
      \"lastName\":\"$lastname\",
      \"credentials\":[{
        \"type\":\"password\",
        \"value\":\"$password\",
        \"temporary\":false
      }]
    }"
}

create_user "user1" "password1" "John" "Doe"
create_user "user2" "password2" "Jane" "Smith"

# Create Grafana client
curl -s -X POST http://localhost:8080/admin/realms/$REALM_NAME/clients \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"clientId\":\"$CLIENT_ID\",
    \"enabled\":true,
    \"clientAuthenticatorType\":\"client-secret\",
    \"secret\":\"$CLIENT_SECRET\",
    \"redirectUris\":[\"$GRAFANA_URL/*\"],
    \"webOrigins\":[\"$GRAFANA_URL\"],
    \"publicClient\":false,
    \"protocol\":\"openid-connect\",
    \"standardFlowEnabled\":true
  }"

echo "Keycloak setup complete!"
echo "Realm: $REALM_NAME"
echo "Client ID: $CLIENT_ID"
echo "Client Secret: $CLIENT_SECRET"
echo "Keycloak URL: http://localhost:8080"

