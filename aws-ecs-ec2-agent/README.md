# AWS: Send logs from an ECS task on EC2 to Grafana Cloud Logs with Grafana Agent

This example shows how to collect logs from tasks running on ECS EC2 instances, using Grafana Agent.

## What's in this example

This example includes Terraform configuration for the following:

- An Elastic Container Service (ECS) cluster consisting of a single EC2 VM instance

- ECS Task definition and Service for a demo app, which just writes a sample log to stdout

- ECS Task definition and Service that runs Grafana Agent, mounting the Docker socket so Agent can collect logs from other containers running on the same host

- Some cloud-init "glue" to configure a Grafana Agent configuration file on the host, so it can be bind-mounted into the Agent container

## To deploy

1.  Rename the file `terraform.tfvars.example` to `terraform.tfvars`, and fill in the variables with your Grafana Cloud credentials and Loki/Prometheus endpoints.

2.  Run the following commands:

    ```shell
    cd terraform

    terraform init

    terraform apply
    ```

After some moments you should see some Logs appear in Grafana Cloud.

## Debugging

Once the infrastructure is up and running, you can SSH into the ECS EC2 instance using [AWS Systems Manager][1] &rarr; Session Manager, if you want to inspect the configuration, e.g. `sudo docker ps` to see the running containers, or `sudo cat /etc/agent/agent.yaml` to inspect the Agent config file.

[1]: https://eu-west-1.console.aws.amazon.com/systems-manager/home
