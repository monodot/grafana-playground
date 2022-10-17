# gem-gel-get-on-kube

**⚠ WORK IN PROGRESS.**

Looking at how to deploy these things onto Kubernetes on Google Cloud:

- Grafana Enterprise
- Grafana Enterprise Metrics
- Grafana Enterprise Traces
- Grafana Enterprise Logs

## Pre-requisites

- A Kubernetes cluster with persistent storage.
- A licence for Grafana Enterprise that matches the URL you will deploy to.
- A licence for Grafana Enterprise Logs.

## Deploy Grafana Enterprise

💁 See <https://grafana.com/docs/grafana/latest/setup-grafana/installation/kubernetes/#deploy-grafana-enterprise-on-kubernetes>

Deploy Grafana Enterprise first:

```
STATIC_IP_NAME=my-ip-address-for-grafana
GCP_PROJECT=project-to-deploy-into
GCP_REGION=us-central1
GRAFANA_URL=http://grafana.labs.mndt.co.uk/

helm repo add grafana https://grafana.github.io/helm-charts

helm repo update

kubectl create namespace grafana

kubectl -n grafana create secret generic ge-license --from-file=license.jwt=/path/to/license-grafana.jwt

envsubst < grafana/configmap.yaml | kubectl -n grafana apply -f -

kubectl -n grafana apply -f grafana/deployment.yaml 
```

Set up some GCP networking [^1]:

```
gcloud config set project ${GCP_PROJECT}
gcloud config set compute/zone ${GCP_ZONE}

# Create a "global" IP address to use with an Ingress object
gcloud compute addresses create ${STATIC_IP_NAME} --project=${GCP_PROJECT} --global

envsubst < grafana/ingress.yaml | kubectl -n grafana apply -f -
```

Finally, in your DNS provider, create an A-record to point to the Google Cloud static IP address. This should allow you to access Grafana at the URL given in the _grafana.ini_. 

## Deploy Grafana Enterprise Logs

Pre-requisites:

- Obtain a licence for Grafana Enterprise Logs (GEL) and download the licence file.

Steps:

```
kubectl create namespace gel
```

Deploy Minio which provides an S3-compatible storage service:

```
kubectl -n gel apply -f gel/minio-deployment.yaml

# To verify the deployment (optional step)
kubectl -n gel port-forward svc/minio-console 40779
xdg-open http://localhost:40779
```

Deploy GEL:

```
kubectl -n gel create secret generic ge-logs-license --from-file=license.jwt=/path/to/license-gel.jwt

kubectl -n gel apply -f gel/configmap.yaml

kubectl -n gel apply -f gel/services.yaml

kubectl -n gel apply -f gel/statefulset.yaml

kubectl -n gel apply -f gel/compactor.yaml
```

Generate an admin token for Loki - we'll need this when we configure the GEL plugin for Grafana:

```
kubectl -n gel apply -f gel/tokengen-job.yaml
```

### Set up GEL in Grafana

Finally, go to **Grafana > Configuration menu > Plugins > Grafana Enterprise Logs plugin** and add the following settings:

- **Access token:** the token you saved above

- **Grafana Enterprise Logs URL:** `http://ge-logs.gel.svc.cluster.local:8100`

Then click **Enable plugin**.

Now you should be able to navigate to the **Grafana Enterprise Logs** "tab" in Grafana to:

- Add a new GEL tenant

- Observe the health of your 3-node GEL cluster

- Set access policies

...etc.

### Push some sample data into GEL

In the Grafana Enterprise Logs interface in Grafana, create a new push token. Start by creating an Access Policy:

- Give it a name of your choice

- Say 'no' when asked if you're going to create a datasource with this policy

- Select the **logs:write** scope

- Choose your tenant (create one if you haven't already) and click **Create**.

- Then click the **Add token** button by the side of the access policy to generate a new token. **Copy the token.**

Then, start a `port-forward` and send some sample text to Loki to index:

```
kubectl -n gel port-forward svc/ge-logs 8100

export GEL_PUSH_TOKEN=yourtokengoeshere
export GEL_TEST_TIME=$(date +%s%N)
export GEL_TENANT_ID=your_gel_tenantid

curl -v -u ${GEL_TENANT_ID}:$GEL_PUSH_TOKEN \
  -H "Content-Type: application/json" \
  -H "X-Scope-OrdID: ${GEL_TENANT_ID}" \
  -X POST \
  http://localhost:8100/loki/api/v1/push --data @- <<EOF
{
  "streams": [
    {
      "stream": {
        "job": "test_load",
        "meal": "breakfast"
      },
      "values": [
          [ "${GEL_TEST_TIME}", "my log line is here" ],
          [ "${GEL_TEST_TIME}", "peanut butter on toast" ]
      ]
    }
  ]
}
EOF
```

#### See the sample data in GEL

Now we can check that the test data was stored by hitting the API:

```
export GEL_READ_TOKEN=a_token_that_can_read_goes_here

curl -u ${GEL_TENANT_ID}:${GEL_READ_TOKEN} http://localhost:8100/loki/api/v1/labels
```

Which should return something like:

```
{
  "status": "success",
  "data": [
    "job",
    "meal"
  ]
}
```

### Seeing the list of tenants in GEL

We can also view tenants using the GEL admin api. Try the following API call:

```
curl -u :$GEL_ADMIN_TOKEN http://localhost:8100/admin/api/v3/tenants
```

...which should return something like this:

```json
{
  "items": [
    {
      "name": "__system__",
      "display_name": "System",
      "created_at": "1970-01-01T00:00:00Z",
      "status": "active",
      "cluster": "tomdonohuegel"
    },
    {
      "name": "henlo-borb",
      "display_name": "Henlo Borb",
      "created_at": "2022-10-17T12:01:47.037402963Z",
      "status": "active",
      "cluster": "tomdonohuegel",
      "limits": {
        "ingestion_rate": 0,
        "ingestion_burst_size": 0,
        "max_global_series_per_user": 0,
        "max_global_series_per_metric": 0,
        "max_global_exemplars_per_user": 0,
        "ruler_max_rules_per_rule_group": 0,
        "ruler_max_rule_groups_per_tenant": 0,
        "max_fetched_chunks_per_query": 0,
        "max_fetched_series_per_query": 0,
        "max_fetched_chunk_bytes_per_query": 0,
        "compactor_blocks_retention_period": "0s"
      }
    }
  ],
  "type": "tenant"
}
```

[^1]: https://cloud.google.com/kubernetes-engine/docs/tutorials/configuring-domain-name-static-ip
