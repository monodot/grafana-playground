# Terraform: create stack and set up LBAC for Loki

This is an example Terraform configuration for setting up Loki LBAC in Grafana Cloud.

## Preparation

1. Go to the Grafana Cloud self-service portal -> Access Policies - e.g. `https://grafana.com/orgs/<YOUR_ORG>/access-policies`. 

1. Create a new access policy with the following details:
    - Realms: (all stacks)
    - Scopes:
        - datasources: read, write, delete
        - access-policies: read, write, delete
        - orgs: read
        - stack-service-accounts: write
        - stack: read, write, delete

1. After you've created the access policy, generate a token. Copy the token, because it will be needed in the next step.

## Deployment

To provision a new Grafana Cloud stack, with a limited "developer" access policy and Loki data source, run the following commands:

```
export TF_VAR_grafana_cloud_api_key="<your-access-token>"

terraform init

terraform apply
```

## Test

Now ship some test logs:

1.  Make a copy of the file `.env.example` and replace with the URL and token for your Loki instance.

2.  Next, run the [Compose][compose] configuration, which will start the demo app (one simulating "development", and one simulating "production") and Promtail, and begin sending logs to your Grafana Cloud stack:

    ```shell
    docker compose up

    # or: podman-compose up
    ```

[compose]: https://compose-spec.io/

