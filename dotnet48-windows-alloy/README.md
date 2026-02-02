# .NET Framework 4.8 and Alloy on Windows VMs

A .NET Framework application running on IIS, instrumented with OpenTelemetry, shipping signals to a local Alloy and onward to Grafana Cloud. Deploys on Azure.

This demo consists of:

- 3 Windows VMs in Azure, with the following installed on each:
  - The [cheese-app](https://github.com/monodot/dotnet-playground/tree/main/cheese-app) ASP.NET Web API application (.NET Framework 4.8)
  - IIS
  - Grafana Alloy, configured to ship telemetry to Grafana Cloud
- Azure load balancer, to access the demo app
- Azure Cache for Redis (Basic tier), accessible from all VMs

## Instructions

### Authenticate to Azure and set up the infrastructure

Install the azure-cli and authenticate to Azure (instructions for Fedora/dnf based distros):

```sh
sudo dnf install azure-cli

az config set core.login_experience_v2=off
az login
```

Select the subscription:

```sh
az account set --subscription "<your-subscription-goes-here>"

# Confirm: The output of this command should show the name of your chosen subscription
az account show --query name -o tsv
```

Set your variables in terraform.tfvars, paying particular attention to:

- `allowed_ip` - ensure this is set to your **current IP address** (this ensures you will be permitted to RDP to the virtual machines

Next, create the infrastructure:

```sh
cd terraform

terraform init

terraform apply
```

### Access the application

Once the infrastructure is deployed, access the demo application:

```sh
# Get the application URL from Terraform output
terraform output application_url
```

#### Test the REST API

The application exposes several REST endpoints:

```sh
# Get values
curl http://<load-balancer-ip>/api/values

# Get specific value
curl http://<load-balancer-ip>/api/values/5

# Create value
curl -X POST http://<load-balancer-ip>/api/values \
  -H "Content-Type: application/json" \
  -d '"test"'
  
# Redis interaction
curl http://<load-balancer-ip>/api/redis/status
```

Each request will be load balanced across the 3 VMs.

### Access Redis

Get the Redis connection details:

```sh
terraform output redis_hostname

terraform output -raw redis_primary_key
```

To connect from a .NET application, use a connection string like:

```
<hostname>:6380,password=<primary_key>,ssl=True,abortConnect=False
```

All three VMs can connect to Redis using these credentials. Redis is accessible only from within the virtual network (10.0.2.0/24).

### Access the VMs

Using an RDP client (like Remmina), connect to one of the VMs:

1. **IP address:** Use the `vm_rdp_addresses` output from Terraform to choose a VM to connect to.
2. **Connect** to the VM instance using `adminuser` and the password you set in the TF var `admin_password`
3. View Alloy logs: Start > Event Viewer > Windows Logs > Application. Optionally click _Filter current log_ and set _Event source_ to **Alloy**, to show only Alloy logs.
4. View IIS logs: `C:\inetpub\logs\LogFiles\W3SVC*\` 

### Observe in Grafana Cloud