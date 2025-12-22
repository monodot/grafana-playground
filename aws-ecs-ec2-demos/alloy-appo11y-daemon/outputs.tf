output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.workshop.name
}

output "ec2_instance_ids" {
  description = "IDs of the EC2 instances running ECS tasks"
  value       = aws_instance.ecs_node[*].id
}

output "ec2_public_ips" {
  description = "Public IP addresses of the EC2 instances"
  value       = aws_instance.ecs_node[*].public_ip
}

output "ec2_private_ips" {
  description = "Private IP addresses of the EC2 instances (use these for OTLP endpoints within VPC)"
  value       = aws_instance.ecs_node[*].private_ip
}

output "otlp_grpc_endpoints_private" {
  description = "OTLP gRPC endpoints for sending telemetry (private IPs, use from within VPC)"
  value       = [for ip in aws_instance.ecs_node[*].private_ip : "http://${ip}:4317"]
}

output "otlp_http_endpoints_private" {
  description = "OTLP HTTP endpoints for sending telemetry (private IPs, use from within VPC)"
  value       = [for ip in aws_instance.ecs_node[*].private_ip : "http://${ip}:4318"]
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group for Alloy logs"
  value       = aws_cloudwatch_log_group.alloy_logs.name
}

output "security_group_id" {
  description = "Security group ID for ECS cluster instances"
  value       = aws_security_group.ecs_cluster.id
}

output "telemetrygen_service_name" {
  description = "Name of the telemetrygen demo service"
  value       = aws_ecs_service.telemetrygen.name
}

output "telemetrygen_log_group" {
  description = "CloudWatch log group for telemetrygen logs"
  value       = aws_cloudwatch_log_group.telemetrygen_logs.name
}