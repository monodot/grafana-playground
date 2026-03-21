# ── IAM — Grafana Cloud CloudWatch data source ────────────────────────────────

resource "aws_iam_policy" "grafana_cloudwatch" {
  name = "${var.name_prefix}-grafana-cloudwatch-read"
  tags = local.common_tags

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "cloudwatch:ListMetrics",
        "cloudwatch:GetMetricData",
        "cloudwatch:GetMetricStatistics",
        "cloudwatch:DescribeAlarms",
        "logs:DescribeLogGroups",
        "logs:GetLogGroupFields",
        "logs:StartQuery",
        "logs:StopQuery",
        "logs:GetQueryResults",
        "logs:GetLogEvents",
        "tag:GetResources",
        "ec2:DescribeRegions",
      ]
      Resource = "*"
    }]
  })
}

resource "aws_iam_user" "grafana_cloudwatch" {
  name = "${var.name_prefix}-grafana-cloudwatch"
  tags = local.common_tags
}

resource "aws_iam_user_policy_attachment" "grafana_cloudwatch" {
  user       = aws_iam_user.grafana_cloudwatch.name
  policy_arn = aws_iam_policy.grafana_cloudwatch.arn
}

resource "aws_iam_access_key" "grafana_cloudwatch" {
  user = aws_iam_user.grafana_cloudwatch.name
}

# ── Outputs ───────────────────────────────────────────────────────────────────
# Secret is marked sensitive; retrieve with: terraform output -raw grafana_cloudwatch_secret

output "grafana_cloudwatch_access_key_id" {
  value = aws_iam_access_key.grafana_cloudwatch.id
}

output "grafana_cloudwatch_secret" {
  value     = aws_iam_access_key.grafana_cloudwatch.secret
  sensitive = true
}
