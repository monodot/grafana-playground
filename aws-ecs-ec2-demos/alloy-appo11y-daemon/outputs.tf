output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.workshop.name
}

output "ec2_instance_id" {
  description = "ID of the EC2 instance running ECS tasks"
  value       = aws_instance.ecs_node.id
}

output "ec2_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.ecs_node.public_ip
}

output "ec2_private_ip" {
  description = "Private IP address of the EC2 instance (use this for OTLP endpoints within VPC)"
  value       = aws_instance.ecs_node.private_ip
}

output "otlp_grpc_endpoint_private" {
  description = "OTLP gRPC endpoint for sending telemetry (private IP, use from within VPC)"
  value       = "http://${aws_instance.ecs_node.private_ip}:4317"
}

output "otlp_http_endpoint_private" {
  description = "OTLP HTTP endpoint for sending telemetry (private IP, use from within VPC)"
  value       = "http://${aws_instance.ecs_node.private_ip}:4318"
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group for Alloy logs"
  value       = aws_cloudwatch_log_group.alloy_logs.name
}

output "security_group_id" {
  description = "Security group ID for ECS cluster instances"
  value       = aws_security_group.ecs_cluster.id
}