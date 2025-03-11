# alloy-helm-gcplogs

Shows how to deploy Alloy with the Helm chart, configured with authentication to Google Cloud Platform to pull logs from a PubSub topic.

## To deploy

Deploy the infrastructure (PubSub topic, Subscription, IAM user, permissions):

```shell
cd terraform

terraform -chdir=terraform init

terraform -chdir=terraform apply
# Give your GCP project name, when prompted
```

Extract the JSON key file and pop into a Secret:

```shell
terraform -chdir=terraform output -raw service_account_key | base64 --decode > service-account-key.json

kubectl create ns myalloy

kubectl -n myalloy create secret generic gcp-logs --from-file=service-account-key.json=service-account-key.json
```

Deploy Alloy (well, render the template first so we can inspect it, then apply it):

```shell
helm template myalloy grafana/alloy --namespace myalloy --create-namespace -f values.yaml > rendered.yaml

kubectl -n myalloy apply -f rendered.yaml
```

Send a message to the PubSub topic:

```shell
gcloud pubsub topics publish sandwiches --message="Hello, PubSub!"
```

Finally, observe that Alloy has received the message:

```shell
kubectl -n myalloy logs 
```

You can also fetch messages from the Subscription locally:

```shell
gcloud auth activate-service-account --key-file=service-account-key.json

gcloud pubsub subscriptions pull sandwiches-subscription --auto-ack --project YOUR_PROJECT_ID
```
