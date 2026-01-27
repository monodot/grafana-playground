# .NET Framework 4.8 and Alloy on Windows VMs

Demo scenario consisting of:

- 3 Windows VMs in Azure, with the following installed on each:
  - A simple ASP.NET demo application
  - IIS
  - Grafana Alloy, configured to ship telemetry to Grafana Cloud
- Azure load balancer, to access the demo app

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

Visit the URL in your browser. You'll see a simple page showing:
- The server hostname (which VM handled the request)
- .NET Framework version
- Request timestamp
- Your client IP

Refresh the page multiple times to see the load balancer distributing requests across the 3 VMs.

### Access the VMs

Using an RDP client (like Remmina), connect to one of the VMs:

1. **IP address:** Use the `vm_rdp_addresses` output from Terraform to choose a VM to connect to.
2. **Connect** to the VM instance using `adminuser` and the password you set in the TF var `admin_password`
3. View Alloy logs: Start > Event Viewer > Windows Logs > Application. Optionally click _Filter current log_ and set _Event source_ to **Alloy**, to show only Alloy logs.
4. View IIS logs: `C:\inetpub\logs\LogFiles\W3SVC*\` 

### Observe in Grafana Cloud