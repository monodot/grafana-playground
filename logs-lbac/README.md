# logs-lbac (Label-Based Access Control)

This demo shows how to restrict access to logs in Grafana Cloud Logs, using Cloud Access Policies.

- This example starts two identical containers, which each write some random logs

- It also starts a Promtail container, which collects the logs from the two application containers and sends them to Grafana Cloud Logs

- An associated Terraform configuration creates a Cloud Access Policy and Token

## Getting started

### Create a Cloud Access Policy and a token

1. Run the provided Terraform to create a Cloud Access Policy in your Grafana Cloud organisation:

    ```shell
    cd terraform

    terraform init

    terraform apply
    # You will be asked for values for:
    # grafana_cloud_api_key, grafana_cloud_org_slug, grafana_cloud_region

    terraform output grafana_cloud_access_policy_token
    ```

2.  Make a note of the output value in the final step. You'll need it later, to add a new datasource.

### Run the demo app and Promtail

1.  Make a copy of the file `.env.example`, edit the values to suit your environment, and save it as `.env`.

2.  Next, run the [Compose][compose] configuration, which will start the demo app (one simulating "development", and one simulating "production") and Promtail, and begin sending logs to your Grafana Cloud stack:

```shell
docker compose up

# or: podman-compose up
```

### View logs in Grafana Cloud (optional)

To see LBAC in action, you'll need to add an extra user to your Grafana Cloud account, so you can see how their access is restricted. You'll also need to create a new, limited datasource, and grant access to it to the new user.

#### 1. Remove access to the default logs datasource

- In Administration &rarr; Data sources &rarr; grafanacloud-yourname-logs &rarr; Permissions, remove access to this datasource for Viewer and Editor roles.

#### 2. Add a new datasource

- Create a new Logs datasource in Grafana Cloud Logs, using the token you created earlier. Call it "Logs for Developers" or a meaningful name.

#### 3. Allow access to the new logs datasource to developer users

- Invite 1 or more users to your Grafana Cloud org.

- In Grafana &rarr; Administration &rarr; Teams, create a new Team.

- In the team management page, add your invited developer user(s) to the team.

- Go to your newly-created "Logs for Developers" datasource &rarr; Permissions. Click _Add permission_ and grant the Developers team the "Query" permission on this datasource.

Now your developers should be able to query the logs labelled with "development", but not others.

You can verify this by logging in as your invited developer user, going to the Explore view, and observe that they can only see the "Logs for Developers" datasource.



[compose]: https://compose-spec.io/
