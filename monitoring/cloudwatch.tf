# This file is intentionally separate from the main terraform/ directory
# so monitoring resources can be applied independently.
# Include these in your root module by referencing the monitoring/ folder.

resource "aws_cloudwatch_metric_alarm" "web_high_cpu" {
  alarm_name          = "web-tier-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "Web tier CPU > 70% for 4 minutes"

  dimensions = {
    AutoScalingGroupName = "web-asg"
  }
}

resource "aws_cloudwatch_metric_alarm" "app_high_cpu" {
  alarm_name          = "app-tier-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "App tier CPU > 70% for 4 minutes"

  dimensions = {
    AutoScalingGroupName = "app-asg"
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_connections" {
  alarm_name          = "rds-high-connections"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Maximum"
  threshold           = 80
  alarm_description   = "RDS connection count exceeds 80"

  dimensions = {
    DBInstanceIdentifier = "three-tier-db"
  }
}

resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/three-tier/app"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "web_logs" {
  name              = "/three-tier/web"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/three-tier-deploy-trigger"
  retention_in_days = 14
}
