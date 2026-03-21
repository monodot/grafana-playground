output "function_url" {
  description = "HTTPS URL to invoke this Lambda variant"
  value       = var.snapstart_enabled ? aws_lambda_function_url.snapstart[0].function_url : aws_lambda_function_url.latest[0].function_url
}

output "function_name" {
  value = aws_lambda_function.this.function_name
}

output "function_arn" {
  value = aws_lambda_function.this.arn
}
