resource "aws_s3_bucket" "fallback" {
  bucket        = "${var.service_namespace}-firehose-fallback-${var.environment_id}"
  force_destroy = true

  tags = {
    Name        = "${var.service_namespace}-firehose-fallback-${var.environment_id}"
    Environment = var.environment_id
    Namespace   = var.service_namespace
  }
}

resource "aws_iam_role" "firehose" {
  name = "${var.service_namespace}-firehose-role-${var.environment_id}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "firehose.amazonaws.com"
        }
      },
    ],
  })
}

resource "aws_iam_role_policy" "firehose" {
  name = "${var.service_namespace}-firehose-policy-${var.environment_id}"
  role = aws_iam_role.firehose.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # allow firehose to r/w the fallback bucket
      {
        Action = [
          "s3:AbortMultipartUpload",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:PutObject",
        ]
        Effect = "Allow"
        Resource = [
          format("arn:aws:s3:::%s", aws_s3_bucket.fallback.id),
          format("arn:aws:s3:::%s/*", aws_s3_bucket.fallback.id),
        ]
      },
      # allow firehose to write error logs
      {
        Effect = "Allow"
        Resource : ["*"],
        Action = ["logs:PutLogEvents"]
      }
    ]
  })
}



resource "aws_kinesis_firehose_delivery_stream" "ecs_events" {
  name        = "${var.service_namespace}-ecs-events-${var.environment_id}"
  destination = "http_endpoint"

  // this block configures the main destination of the delivery stream
  http_endpoint_configuration {
    url            = var.grafana_cloud_firehose_target_endpoint
    name           = "Grafana AWS Logs Destination"
    access_key     = format("%s:%s", var.grafana_cloud_logs_instance_id, var.grafana_cloud_access_policy_token)
    buffering_size = 1 // Buffer incoming data to the specified size, in MBs, before delivering it to the destination

    // Buffer incoming data for the specified period of time, in seconds, before delivering it to the destination
    // Setting to 1 minute to keep a low enough latency between log production and actual time they are processed in Loki
    buffering_interval = 60

    role_arn       = aws_iam_role.firehose.arn
    s3_backup_mode = "FailedDataOnly"

    request_configuration {
      content_encoding = "GZIP"

      # common_attributes {
      #   name  = "lbl_service_name"
      #   value = "mythical-beasts-database"
      # }
      # common_attributes {
      #   name  = "lbl_service_namespace"
      #   value = "tickets"
      # }
      common_attributes {
        name  = "lbl_cloud_region"
        value = data.aws_region.current.name
      }
    }

    s3_configuration {
      role_arn           = aws_iam_role.firehose.arn
      bucket_arn         = aws_s3_bucket.fallback.arn
      buffering_size     = 5
      buffering_interval = 300
      compression_format = "GZIP"
    }

    dynamic "cloudwatch_logging_options" {
      for_each = var.firehose_log_delivery_errors ? [1] : []
      content {
        enabled         = true
        log_group_name  = "${var.service_namespace}-firehose-errors-${var.environment_id}"
        log_stream_name = "firehose-errors"
      }
    }
  }
}

resource "aws_cloudwatch_event_rule" "ecs_events" {
  name        = "${var.service_namespace}-ecs-events-${var.environment_id}"
  description = "ECS Events to Firehose Delivery Stream"

  event_pattern = jsonencode({
    source      = ["aws.ecs"],
    detail-type = ["ECS Task State Change", "ECS Container Instance State Change", "ECS Deployment State Change"]
  })
}

resource "aws_cloudwatch_event_target" "ecs_events_firehose" {
  rule      = aws_cloudwatch_event_rule.ecs_events.name
  target_id = "ship-to-firehose"
  arn       = aws_kinesis_firehose_delivery_stream.ecs_events.arn
  role_arn  = aws_iam_role.eventbridge_to_firehose.arn
}

resource "aws_iam_policy" "eventbridge_to_firehose" {
  name        = "${var.service_namespace}-eventbridge-to-firehose-${var.environment_id}"
  description = "Policy for EventBridge to invoke Firehose Delivery Stream"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "ActionsForFirehose"
        Effect   = "Allow"
        Action   = ["firehose:PutRecord", "firehose:PutRecordBatch"]
        Resource = [aws_kinesis_firehose_delivery_stream.ecs_events.arn]
      },
    ]
  })
}

resource "aws_iam_role" "eventbridge_to_firehose" {
  name = "${var.service_namespace}-eventbridge-invoke-firehose-${var.environment_id}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "events.amazonaws.com"
        }
      },
    ],
  })
}

resource "aws_iam_role_policy_attachment" "eventbridge_to_firehose" {
  role       = aws_iam_role.eventbridge_to_firehose.name
  policy_arn = aws_iam_policy.eventbridge_to_firehose.arn
}
