# AWS: Send logs from an ECS task on EC2 to Grafana Cloud Logs with Grafana Agent

To deploy:

```
terraform init

terraform apply
```

Once the infrastructure is up and running, you can SSH into the VM using [AWS Systems Manager][1] &rarr; Session Manager.

[1]: https://eu-west-1.console.aws.amazon.com/systems-manager/home
