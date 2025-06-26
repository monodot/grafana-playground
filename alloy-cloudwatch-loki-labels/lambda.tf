resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.function_name}-${data.external.whoami.result.user}"
  retention_in_days = 14
  tags              = local.common_tags
}

resource "aws_iam_role" "lambda_role" {
  name = "${var.function_name}-role"

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

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_role.name
}

resource "null_resource" "install_dependencies" {
  triggers = {
    # Rebuild when source files change
    index_js_hash    = filemd5("${path.module}/function/index.js")
    package_json_hash = filemd5("${path.module}/function/package.json")
  }

  provisioner "local-exec" {
    command = "cd ${path.module}/function && npm init -y && npm install uuid"
  }
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/function"
  output_path = "${path.module}/lambda_function.zip"

  depends_on = [null_resource.install_dependencies]
}

resource "aws_lambda_function" "example_lambda" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.function_name}-${data.external.whoami.result.user}"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  depends_on = [aws_cloudwatch_log_group.lambda]

  tags = local.common_tags
}

