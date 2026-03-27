output "config_1_url"  { value = module.config_1.function_url }
output "config_2_url"  { value = module.config_2.function_url }
output "config_3_url"  { value = module.config_3.function_url }
output "config_4_url"  { value = module.config_4.function_url }
output "config_5_url"  { value = module.config_5.function_url }
output "config_6_url"  { value = module.config_6.function_url }
output "config_7_url"  { value = module.config_7.function_url }
output "config_8_url"  { value = module.config_8.function_url }
output "config_9_url"  { value = module.config_9.function_url }
output "config_10_url" { value = module.config_10.function_url }
output "config_11_url" { value = module.config_11.function_url }

output "ecs_collector_endpoint" {
  description = "NLB DNS name for the external OTel Collector (config 5)"
  value       = aws_lb.ecs_collector.dns_name
}
