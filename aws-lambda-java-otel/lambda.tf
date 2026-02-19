resource "aws_s3_bucket" "receipts" {
  bucket        = "order-receipts-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
  tags          = local.common_tags
}

resource "aws_s3_bucket_public_access_block" "receipts" {
  bucket                  = aws_s3_bucket.receipts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.function_name}-${data.external.whoami.result.user}"
  retention_in_days = 14
  tags              = local.common_tags
}

resource "aws_iam_role" "lambda_role" {
  name = "${var.function_name}-role-${data.external.whoami.result.user}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_role.name
}

resource "aws_iam_role_policy" "lambda_s3" {
  name = "${var.function_name}-s3-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject"]
        Resource = "${aws_s3_bucket.receipts.arn}/receipts/*"
      }
    ]
  })
}

# Build the fat JAR whenever source files change.
# The JAR is produced at function/target/example-java-1.0-SNAPSHOT.jar by the
# maven-shade-plugin configured in pom.xml.
resource "null_resource" "build_jar" {
  triggers = {
    pom_hash     = filemd5("${path.module}/function/pom.xml")
    handler_hash = filemd5("${path.module}/function/src/main/java/example/OrderHandler.java")
  }

  provisioner "local-exec" {
    command = "cd ${path.module}/function && ./mvnw package -q"
  }
}

resource "aws_lambda_function" "order_handler" {
  filename      = "${path.module}/function/target/example-java-1.0-SNAPSHOT.jar"
  function_name = "${var.function_name}-${data.external.whoami.result.user}"
  role          = aws_iam_role.lambda_role.arn
  handler       = "example.OrderHandler"
  runtime       = "java21"
  timeout       = 30
  memory_size   = 512

  # Derived from source file hashes so Terraform detects changes without
  # needing to hash the JAR at plan time (before the build runs).
  source_code_hash = sha256(join("", [
    null_resource.build_jar.triggers["pom_hash"],
    null_resource.build_jar.triggers["handler_hash"],
  ]))

  environment {
    variables = {
      RECEIPT_BUCKET = aws_s3_bucket.receipts.bucket
    }
  }

  depends_on = [
    null_resource.build_jar,
    aws_cloudwatch_log_group.lambda,
  ]

  tags = local.common_tags
}
