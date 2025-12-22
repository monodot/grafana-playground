# Alloy: Deploy as DAEMON to collect OTLP signals

Deploy Grafana Alloy as an ECS daemon on EC2 to collect OpenTelemetry Protocol (OTLP) signals from applications and forward them to Grafana Cloud.

## Overview

This Terraform configuration deploys:
- ECS cluster on EC2 (single instance for demo)
- Grafana Alloy running as a daemon service (one per EC2 host)
- Security group allowing OTLP traffic only within the ECS cluster
- CloudWatch log group for Alloy container logs
- SSM Parameter Store for Alloy configuration

Alloy accepts OTLP signals (traces, metrics, logs) and forwards them to Grafana Cloud using OTLP HTTP.

## Architecture

```
┌─────────────────────────────────────────────┐
│ EC2 Instance (ECS Container Instance)       │
│                                             │
│  ┌────────────────────────────────────┐     │
│  │ Alloy Container (DAEMON)           │     │
│  │                                    │     │
│  │  OTLP Receiver                     │     │
│  │    ↓ gRPC :4317                    │     │
│  │    ↓ HTTP :4318                    │     │
│  │  Batch Processor                   │     │
│  │    ↓                               │     │
│  │  OTLP HTTP Exporter ───────────────┼─────┼──→ Grafana Cloud
│  │                                    │     │
│  └────────────────────────────────────┘     │
│                                             │
└─────────────────────────────────────────────┘
```

Configuration is stored in SSM Parameter Store and fetched by the container at startup.

## Prerequisites

1. **AWS Account**: With credentials configured (e.g., via `aws sso login` or environment variables)
2. **Grafana Cloud Account**: You'll need:
   - OTLP endpoint URL (e.g., `https://otlp-gateway-prod-us-central-0.grafana.net/otlp`)
   - Instance ID (username for authentication)
   - API key (password for authentication)

   To get these values:
   - Log in to Grafana Cloud
   - Navigate to **Connections** > **Add new connection** > **OpenTelemetry (OTLP)**
   - Copy the endpoint URL and instance ID
   - Generate an API key with metrics, logs, and traces write permissions

3. **Terraform**: Version 1.0+ installed

## Setup

1. Copy the example variables file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars` with your values:
   ```hcl
   owner                       = "your-name"
   environment_id              = "demo"
   grafana_cloud_otlp_endpoint = "https://otlp-gateway-prod-us-central-0.grafana.net/otlp"
   grafana_cloud_instance_id   = "123456"
   grafana_cloud_api_key       = "glc_xxx...xxx"
   ```

3. Configure AWS credentials:
   ```bash
   aws sso login --sso-session <session-name>
   export AWS_PROFILE=<profile-name>
   ```

## Deployment

```bash
terraform init
terraform plan
terraform apply
```

After deployment (2-3 minutes), Terraform will output the OTLP endpoints:
```
otlp_grpc_endpoint_private = "http://10.0.1.123:4317"
otlp_http_endpoint_private = "http://10.0.1.123:4318"
```

**Note**: The OTLP endpoints use private IPs because the security group only allows traffic from within the ECS cluster security group. To send test traffic, you'll need to run your application in the same VPC or use Session Manager to access the EC2 instance.

## Testing

### Option 1: Deploy a test application in the same ECS cluster

Deploy an application container to the same ECS cluster, ensure it uses the same security group, and configure it to send OTLP to the private endpoint.

### Option 2: Test from the EC2 instance using Session Manager

1. Connect to the EC2 instance via AWS Session Manager:
   - Go to [AWS Systems Manager → Session Manager](https://console.aws.amazon.com/systems-manager/session-manager)
   - Select the instance named `alloy-daemon-ecs-node-demo`
   - Click "Start session"

2. Install telemetrygen:
   ```bash
   # Install Go
   sudo yum install -y golang

   # Install telemetrygen
   go install github.com/open-telemetry/opentelemetry-collector-contrib/cmd/telemetrygen@latest

   # Add Go bin to PATH
   export PATH=$PATH:~/go/bin
   ```

3. Send test telemetry to localhost:
   ```bash
   # Send traces
   telemetrygen traces --otlp-endpoint localhost:4317 --otlp-insecure

   # Send metrics
   telemetrygen metrics --otlp-endpoint localhost:4317 --otlp-insecure

   # Send logs
   telemetrygen logs --otlp-endpoint localhost:4317 --otlp-insecure
   ```

4. Check Grafana Cloud Explore to see the telemetry data.

## Debugging

### View Alloy Logs

Check CloudWatch Logs:
```bash
aws logs tail /ecs/alloy-daemon-demo --follow
```

### SSH into EC2 Instance

Use AWS Session Manager (no SSH keys required):
1. Go to [AWS Systems Manager → Session Manager](https://console.aws.amazon.com/systems-manager/session-manager)
2. Select the instance named `alloy-daemon-ecs-node-demo`
3. Click "Start session"

Useful commands:
```bash
# View running containers
docker ps

# View Alloy config (fetched from SSM)
cat /etc/alloy/config.alloy

# Check Alloy logs
docker logs $(docker ps -q --filter "name=grafana-alloy")

# View SSM parameter
aws ssm get-parameter --name /alloy-daemon/demo/config --query 'Parameter.Value' --output text
```

### Test OTLP Endpoints

From the EC2 instance:
```bash
# Test gRPC port
nc -zv localhost 4317

# Test HTTP port
nc -zv localhost 4318
```

### Verify ECS Service

Check that the Alloy daemon task is running:
```bash
aws ecs list-tasks --cluster alloy-daemon-cluster-demo
aws ecs describe-tasks --cluster alloy-daemon-cluster-demo --tasks <task-arn>
```

## Security Considerations

- **Network isolation**: Security group only allows OTLP traffic from resources within the same security group (ECS cluster members)
- **Credentials**: Grafana Cloud API key is stored in Terraform state (consider using AWS Secrets Manager for production)
- **SSM Parameter**: Alloy configuration is stored in SSM Parameter Store and fetched at container startup
- **IAM permissions**: Task role has minimal permissions (only SSM parameter read access)

For production deployments, consider:
1. Using AWS Secrets Manager for Grafana Cloud credentials
2. Enabling encryption for SSM parameters
3. Using private subnets with VPC endpoints
4. Implementing TLS for OTLP endpoints
5. Adding authentication/authorization for OTLP endpoints

## Cost Considerations

Estimated AWS costs (us-east-1):
- EC2 t3.micro: ~$7.50/month (if running continuously)
- CloudWatch Logs: Minimal (<$1/month with 7-day retention)
- SSM Parameter Store: Free (standard parameters)
- Data transfer: Varies based on telemetry volume

**Remember to destroy resources when not in use to avoid unnecessary charges.**

## Cleanup

```bash
terraform destroy
```

## How It Works

1. **SSM Parameter Store**: Terraform creates an SSM parameter containing the Alloy configuration
2. **Container Startup**: When the Alloy container starts, it:
   - Installs AWS CLI (via apk on Alpine Linux)
   - Fetches the Alloy config from SSM Parameter Store
   - Writes the config to `/etc/alloy/config.alloy`
   - Starts Alloy with the fetched configuration
3. **OTLP Collection**: Alloy listens on ports 4317 (gRPC) and 4318 (HTTP) for OTLP signals
4. **Forwarding**: Alloy batches and forwards telemetry to Grafana Cloud via OTLP HTTP
5. **DAEMON Scheduling**: ECS ensures one Alloy task runs on each EC2 instance in the cluster

## Scaling

To add more EC2 instances:
1. Update the Terraform configuration to add more `aws_instance` resources
2. Apply the changes
3. The DAEMON scheduling strategy will automatically deploy one Alloy container per instance

For production, consider using an Auto Scaling Group with ECS capacity providers for dynamic scaling.