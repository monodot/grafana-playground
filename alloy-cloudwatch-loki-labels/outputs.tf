output "lambda_function_arn" {
  description = "The ARN of the Lambda function"
  value       = aws_lambda_function.example_lambda.arn
}

output "api_endpoint" {
  description = "HTTP API endpoint URL"
  value       = aws_apigatewayv2_stage.lambda_stage.invoke_url
}
