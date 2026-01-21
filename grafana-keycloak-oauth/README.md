# Grafana: Configuring OAuth SSO using Keycloak

A local Compose configuration showing how to use Keycloak as an SSO provider for Grafana.

```sh
# If you want to enable Enterprise features (Team Sync, etc.)
export GF_ENTERPRISE_LICENSE_TEXT=eyJhb...

podman-compose up
```

Wait for both Grafana and Keycloak to finish starting.

Once they are both up, initialise some users:

```sh
export KEYCLOAK_ADMIN=admin
export KEYCLOAK_ADMIN_PASSWORD=invest-catalina-basin
export REALM_NAME=workshops

export CLIENT_ID=grafana-oauth
export CLIENT_SECRET=bread-and-cakes
export GRAFANA_URL=http://grafana:3000

./keycloak-setup.sh
```

**Access Grafana** at http://localhost:3000:

- user1 / password1
- user2 / password2

**Access Keycloak** at http://localhost:8080:

- Username: admin 
- Password: invest-catalina-basin
