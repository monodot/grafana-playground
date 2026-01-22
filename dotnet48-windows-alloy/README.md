# .NET Framework 4.8 and Alloy on Windows VMs

Demo scenario consisting of an application running on 3 Windows VMs in Azure, running behind a load balancer.

## Getting started

Install the azure-cli and authenticate to Azure (instructions for Fedora/dnf based distros):

```sh
sudo dnf install azure-cli

az login
```

Next, create the infrastructure:

```sh
cd terraform

terraform init

terraform apply
```
