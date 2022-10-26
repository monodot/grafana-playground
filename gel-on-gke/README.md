# gel-on-gke

A journal from deploying the following on Kubernetes on Google Cloud:

- Grafana Enterprise
- Grafana Enterprise Logs

## Pre-requisites

- A Kubernetes cluster with persistent storage.
- A licence for Grafana Enterprise that matches the URL you will deploy to.
- A licence for Grafana Enterprise Logs.

Create a Kube cluster with workload identity enabled:

```
export GCP_PROJECT=your-google-cloud-project-name

gcloud container clusters create ${CLUSTER_NAME} \
    --region=${GCP_REGION} \
    --workload-pool=${GCP_PROJECT}.svc.id.goog
```

Authenticate to your Kubernetes cluster:

```
gcloud container clusters get-credentials ${CLUSTER_NAME} --zone ${GCP_REGION} --project ${GCP_PROJECT}
```

Or, if this is an existing cluster, [enable workload identity on the cluster and the node pools](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity).

## Deploy Grafana Enterprise

💁 See <https://grafana.com/docs/grafana/latest/setup-grafana/installation/kubernetes/#deploy-grafana-enterprise-on-kubernetes>

Deploy Grafana Enterprise first:

```
STATIC_IP_NAME=my-ip-address-for-grafana
GCP_PROJECT=your-google-cloud-project-name
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

export GCP_PROJECT=your-google-cloud-project-name
```

### Set up Google Cloud Storage buckets

Loki needs some persistent storage to store its data. 

We can use Google Cloud Storage for that. We'll use a **Regional (single region)** bucket because it's the cheapest, and still offers redundancy across availability zones [^2]. It also has no data egress charges if it's being accessed from the same region (e.g. the same region as the Kubernetes cluster where Loki is deployed):

```
export GCP_BUCKET_NAME_DATA=my-pet-gel-cluster-data
export GCP_BUCKET_NAME_ADMIN=my-pet-gel-cluster-admin
export GCP_PROJECT=your-gcp-project

gcloud storage buckets create gs://${GCP_BUCKET_NAME_DATA} --location=us-central1 --public-access-prevention --project=${GCP_PROJECT}

gcloud storage buckets create gs://${GCP_BUCKET_NAME_ADMIN} --location=us-central1 --public-access-prevention --project=${GCP_PROJECT}
```

At this point you have a choice of how Loki will authenticate with the Google Cloud Storage API:

1.  Workload Identity. This links a Kubernetes Service Account with an IAM Service Account so that Loki will have the role it needs to write to a storage bucket, but does require the cluster to have Workload Identity enabled. More faff but more secure.

2.  Application Default Credentials. Since Loki uses the Google Cloud Client Libraries (citation needed!), you can also configure its credentials explicitly by setting an environment variable. Less faff but also less secure.

### Create GCP and K8s Service Accounts (if using Workload Identity)

```
export KUBE_SA_NAME=gel-sa
export KUBE_NAMESPACE=yourkkubenamespace
export GCP_SA_NAME=gel-workload-identity

kubectl -n ${KUBE_NAMESPACE} create serviceaccount ${KUBE_SA_NAME}

gcloud iam service-accounts create ${GCP_SA_NAME} \
    --project=${GCP_PROJECT}

gsutil iam ch serviceAccount:${GCP_SA_NAME}@${GCP_PROJECT}.iam.gserviceaccount.com:objectAdmin gs://${GCP_BUCKET_NAME_DATA}

gsutil iam ch serviceAccount:${GCP_SA_NAME}@${GCP_PROJECT}.iam.gserviceaccount.com:objectAdmin gs://${GCP_BUCKET_NAME_ADMIN}

gcloud iam service-accounts add-iam-policy-binding ${GCP_SA_NAME}@${GCP_PROJECT}.iam.gserviceaccount.com \
    --role roles/iam.workloadIdentityUser \
    --member "serviceAccount:${GCP_PROJECT}.svc.id.goog[${KUBE_NAMESPACE}/${KUBE_SA_NAME}]"

kubectl -n ${KUBE_NAMESPACE} annotate serviceaccount ${KUBE_SA_NAME} \
    iam.gke.io/gcp-service-account=${GCP_SA_NAME}@${GCP_PROJECT}.iam.gserviceaccount.com
```

### Create GCP keys (if using Application Default Credentials)

This is required for the GEL Admin client to be able to store its stuff in GCS buckets.

Create a service account and grant object admin permissions on both buckets:

```
export GCP_SA_NAME_FOR_ADMIN=my-pet-cluster-gel-admin

gcloud iam service-accounts create ${GCP_SA_NAME_FOR_ADMIN} \
            --display-name="Tom's GEL Cluster service account for admin storage"

gsutil iam ch serviceAccount:${GCP_SA_NAME_FOR_ADMIN}@${GCP_PROJECT}.iam.gserviceaccount.com:objectAdmin gs://${GCP_BUCKET_NAME_DATA}

gsutil iam ch serviceAccount:${GCP_SA_NAME_FOR_ADMIN}@${GCP_PROJECT}.iam.gserviceaccount.com:objectAdmin gs://${GCP_BUCKET_NAME_ADMIN}
```

Generate a private key which the GEL Admin client can use to authenticate to GCP, and use the Google Cloud Storage API:

```
gcloud iam service-accounts keys create ./sa-private-key.json \
  --iam-account=${GCP_SA_NAME_FOR_ADMIN}@${GCP_PROJECT}.iam.gserviceaccount.com

export GCP_SERVICE_ACCOUNT_JSON=$(cat sa-private-key.json | tr -d '\n')
```

### Deploy GEL with GCS storage backend

Make sure you've got your GCP_SERVICE_ACCOUNT_JSON ready.

Deploy GEL:

```
export GEL_CLUSTER_NAME=name-that-matches-your-licence-key

kubectl -n ${KUBE_NAMESPACE} create secret generic ge-logs-license --from-file=license.jwt=/path/to/license-gel.jwt

envsubst < gel/configmap.yaml | kubectl -n ${KUBE_NAMESPACE} apply -f -

kubectl -n ${KUBE_NAMESPACE} apply -f gel/services.yaml

envsubst < gel/statefulset.yaml | kubectl -n ${KUBE_NAMESPACE} apply -f - 

kubectl -n ${KUBE_NAMESPACE} apply -f gel/compactor.yaml
```

Generate an admin token for Loki - we'll need this when we configure the GEL plugin for Grafana. Run the job then grab the admin token from the logs:

```
kubectl -n ${KUBE_NAMESPACE} apply -f gel/tokengen-job.yaml



kubectl -n ${KUBE_NAMESPACE} logs jobs/ge-logs-tokengen
```

(Optional - if using Application Default Credentials instead of Workload Identity above). Create a secret and set it as an env var:

```
kubectl create secret generic gcp-sa-key --from-file=sa-private-key.json

# After deploying, mount this file into the StatefulSet
# and reference it with an environment variable

kubectl set env sts/ge-logs GOOGLE_APPLICATION_CREDENTIALS=/path/to/key.json
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

### Road test

#### Push some sample data into GEL

In the Grafana Enterprise Logs interface in Grafana, create a new Tenant and a push token. 

Once you've created your Tenant, create an Access Policy:

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

#### See the list of tenants in GEL

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

## Tidy up

When finished, delete everything including the Kubernetes cluster. And don't forget to delete your GEL storage buckets:

```
gcloud storage buckets delete gs://${GCP_BUCKET_NAME_DATA} --project=${GCP_PROJECT}

gcloud storage buckets delete gs://${GCP_BUCKET_NAME_ADMIN} --project=${GCP_PROJECT}
```

[^1]: https://cloud.google.com/kubernetes-engine/docs/tutorials/configuring-domain-name-static-ip
[^2]: https://cloud.google.com/storage/docs/locations

