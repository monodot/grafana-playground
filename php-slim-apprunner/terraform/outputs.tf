output "image_repository_url" {
  description = "ECR repository URL for the application image"
  value       = aws_ecr_repository.this.repository_url
}

output "app_url" {
  description = "URL of the deployed App Runner service"
  value       = aws_apprunner_service.this.service_url
}
