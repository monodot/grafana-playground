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

## Set up Team Sync (optional)

If you want to demo Team Sync, you will need to add a Grafana Enterprise license key, and then:

1. Create a new group in Keycloak (e.g. `developers`) and add a user to it.
2. Navigate to Clients -> grafana-oauth -> Client Scopes
3. Click the `grafana-oauth-dedicated` client scope.
4. Click **Configure a new mapper** -> **Group membership**.
5. Give the new mapper a name, and a _Token Claim Name_. Set _Full group path_ to OFF.
6. In Grafana, create a Team (e.g. _Developers_), and in the _External group sync_ tab, give the external group name (e.g. `developers`) that should be mapped to this Team.
