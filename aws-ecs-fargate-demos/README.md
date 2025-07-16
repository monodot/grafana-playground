# AWS ECS Fargate demos

This repository contains demonstrations of different ways to ship telemetry from AWS ECS Fargate to Grafana Cloud or the Grafana LGTM stack.

## Demo Overview

The repository contains two main demos:

1. **FireLens to Loki** - A simple demo that uses AWS FireLens (Fluent Bit) to ship logs directly from an ECS Fargate task to Grafana Loki.

2. **Alloy Sidecar** - A more advanced demo that uses Grafana Alloy as a sidecar container to collect and process logs before sending them to Loki.

Both demos use:
- AWS ECS with Fargate launch type
- FireLens (a container that runs alongside your application container to route logs)
- Custom labels to enhance log discoverability

Additionally, the repository includes an EventBridge to Firehose integration that captures ECS events and forwards them to Grafana Cloud.

## Key Features

- Sets the `service_name` and `service_namespace` labels on Loki logs, which is essential for easy navigation in Grafana Drilldown Logs
- Demonstrates different deployment patterns for observability in containerized environments
- Shows how to use Grafana Alloy as a sidecar for more advanced telemetry processing
- Includes EventBridge integration to capture AWS service events

## Getting Started

To run these demos, first set the required variables:

1. Set `loki_endpoint` to your Grafana Cloud Logs endpoint (with username, API key and hostname)
2. For the Firehose integration, set the required Grafana Cloud variables:
   - `grafana_cloud_firehose_target_endpoint`
   - `grafana_cloud_logs_instance_id`
   - `grafana_cloud_access_policy_token`

Then run:

```
terraform init
terraform apply
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.9.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_event_rule.ecs_events](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.ecs_events_firehose](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_cloudwatch_log_group.alloy_sidecar](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.firelens_to_loki](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_ecs_cluster.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster) | resource |
| [aws_ecs_service.alloy_sidecar](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_service.firelens_to_loki](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_task_definition.alloy_sidecar](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_ecs_task_definition.firelens_to_loki](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_iam_policy.eventbridge_to_firehose](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.eventbridge_to_firehose](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.firehose](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.task_execution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.firehose](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.ecs_task_execution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.eventbridge_to_firehose](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_kinesis_firehose_delivery_stream.ecs_events](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kinesis_firehose_delivery_stream) | resource |
| [aws_s3_bucket.fallback](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_security_group.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/security_group) | data source |
| [aws_subnet.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |
| [aws_vpc.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_environment_id"></a> [environment\_id](#input\_environment\_id) | n/a | `string` | `"demo"` | no |
| <a name="input_firehose_log_delivery_errors"></a> [firehose\_log\_delivery\_errors](#input\_firehose\_log\_delivery\_errors) | Enable Firehose delivery errors to CloudWatch Logs | `bool` | `false` | no |
| <a name="input_fluent_bit_image"></a> [fluent\_bit\_image](#input\_fluent\_bit\_image) | n/a | `string` | `"grafana/fluent-bit-plugin-loki:3.5"` | no |
| <a name="input_grafana_cloud_access_policy_token"></a> [grafana\_cloud\_access\_policy\_token](#input\_grafana\_cloud\_access\_policy\_token) | Grafana Cloud Logs access policy token for Firehose delivery | `string` | n/a | yes |
| <a name="input_grafana_cloud_firehose_target_endpoint"></a> [grafana\_cloud\_firehose\_target\_endpoint](#input\_grafana\_cloud\_firehose\_target\_endpoint) | Grafana Cloud Firehose target endpoint for logs delivery | `string` | n/a | yes |
| <a name="input_grafana_cloud_logs_instance_id"></a> [grafana\_cloud\_logs\_instance\_id](#input\_grafana\_cloud\_logs\_instance\_id) | Grafana Cloud Logs instance ID for Firehose delivery | `string` | n/a | yes |
| <a name="input_loki_endpoint"></a> [loki\_endpoint](#input\_loki\_endpoint) | n/a | `string` | `"https://123456:aaaaaaaaaa@logs-prod-008.grafana.net/loki/api/v1/push"` | no |
| <a name="input_service_namespace"></a> [service\_namespace](#input\_service\_namespace) | n/a | `string` | `"ecs-fargate-demos"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
