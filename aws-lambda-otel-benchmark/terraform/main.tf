data "aws_caller_identity" "current" {}

data "external" "whoami" {
  program = ["bash", "-c", "printf '{\"user\":\"%s\"}' \"$(whoami)\""]
}

# ── Shared locals ─────────────────────────────────────────────────────────────

locals {
  jar_path = "${path.module}/../function/target/authz-function-1.0-SNAPSHOT.jar"

  # Derived from source-file hashes so Terraform detects changes at plan time
  # without needing to read the JAR itself (which may not yet exist on first plan).
  source_code_hash = sha256(join("", [
    null_resource.build_jar.triggers["pom_hash"],
    null_resource.build_jar.triggers["handler_hash"],
  ]))

  grafana_auth         = base64encode("${var.grafana_cloud_instance_id}:${var.grafana_cloud_access_policy_token}")
  grafana_otlp_headers = "Authorization=Basic ${local.grafana_auth}"

  collector_config_layer_arn = aws_lambda_layer_version.collector_config.arn

  # Owner is resolved at apply time from the local OS user running Terraform.
  # Merges with provider default_tags so all resources carry Project + Owner.
  common_tags = { Owner = data.external.whoami.result.user }
}

