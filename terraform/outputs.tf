output "web_alb_dns" {
  description = "Public DNS of the web-tier ALB"
  value       = aws_lb.web.dns_name
}

output "app_alb_dns" {
  description = "Internal DNS of the app-tier ALB"
  value       = aws_lb.app.dns_name
}

output "rds_endpoint" {
  description = "RDS endpoint address"
  value       = aws_db_instance.main.address
  sensitive   = true
}

output "step_function_arn" {
  description = "ARN of the deployment Step Function"
  value       = aws_sfn_state_machine.deployment.arn
}

output "lambda_function_name" {
  description = "Name of the deploy-trigger Lambda"
  value       = aws_lambda_function.deploy_trigger.function_name
}
