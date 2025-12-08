# AWS ECS/EC2: Collecting Logs with Alloy Daemon for Grafana Cloud

This example shows how to collect logs from tasks running on ECS EC2 instances, using Grafana Alloy running as a Daemon on the VM.

## What's in this example

This example includes Terraform configuration for the following:

- An Elastic Container Service (ECS) cluster, consisting of a single EC2 VM instance

- ECS Task definition and Service for a demo app, which just writes fake HTTP logs to stdout (using `mingrammer/flog`)

- ECS Task definition and Service that runs Grafana Alloy as a daemon, mounting the Docker socket on the EC2 instance, so that Alloy can collect logs from all the containers running on the same host

- Some cloud-init "glue" to create an Grafana Alloy configuration file on the host, which is later mounted into the Alloy container

- ECS Task logs are also sent to CloudWatch, just in case you want to view the logs directly in the AWS Console, but aren't strictly needed

## To deploy

1.  Rename the file `terraform.tfvars.example` to `terraform.tfvars`, and fill in the variables with your Grafana Cloud credentials and Loki endpoint.

2.  Run the following commands:

    ```shell
    cd terraform

    terraform init

    terraform apply
    ```

After some moments you should see some Logs appear in Grafana Cloud.

## Debugging

Once the infrastructure is up and running, you can SSH into the ECS EC2 instance using [AWS Systems Manager][1] &rarr; Session Manager, if you want to inspect the configuration, e.g. `sudo docker ps` to see the running containers, or `sudo cat /etc/alloy/config.alloy` to inspect the Alloy config file.

[1]: https://eu-west-1.console.aws.amazon.com/systems-manager/home
