output "lambda_function_name" {
  description = "Name of the deployed Lambda function"
  value       = aws_lambda_function.order_handler.function_name
}

output "lambda_function_arn" {
  description = "ARN of the deployed Lambda function"
  value       = aws_lambda_function.order_handler.arn
}

output "receipts_bucket" {
  description = "Name of the S3 bucket where order receipts are stored"
  value       = aws_s3_bucket.receipts.bucket
}
