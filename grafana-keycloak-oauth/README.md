# grafana-keycloak-oauth Example

```
podman-compose up

export KEYCLOAK_ADMIN=admin
export KEYCLOAK_ADMIN_PASSWORD=invest-catalina-basin
export REALM_NAME=workshops

export CLIENT_ID=grafana-oauth
export CLIENT_SECRET=bread-and-cakes
export GRAFANA_URL=http://grafana:3000

./keycloak-setup.sh
```
