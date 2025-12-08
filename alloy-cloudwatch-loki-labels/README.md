# Alloy: Extracting Labels from CloudWatch Logs to Loki

This example shows how to deploy Alloy to consume logs from CloudWatch using the OpenTelemetry CloudWatch receiver, and extract the `service.name` attribute from the CloudWatch log group name.

This might be useful if you are ingesting fairly "flat" logs from CloudWatch, but you want to add Loki labels or structured metadata, based on the content of the log message, such as _log level_, _action_, _class name_, etc.

This configuration creates:

- A Lambda function, `loki-structured-metadata-demo`
- A CloudWatch log group, `/aws/lambda/${data.external.whoami.result.user}/${var.function_name}`
- An EC2 instance running Grafana Alloy to consume logs and push to Grafana Cloud

To deploy:

```
terraform init

terraform apply
```

To test:

```
aws lambda invoke --function-name $(terraform output -raw lambda_function_arn) --payload '{}' response.json --region us-east-1
```

