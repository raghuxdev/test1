# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = aws_subnet.public[*].id
}

# Auto Scaling Group Outputs
output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.main.name
}

output "autoscaling_group_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = aws_autoscaling_group.main.arn
}

output "autoscaling_group_min_size" {
  description = "Minimum size of the Auto Scaling Group"
  value       = aws_autoscaling_group.main.min_size
}

output "autoscaling_group_max_size" {
  description = "Maximum size of the Auto Scaling Group"
  value       = aws_autoscaling_group.main.max_size
}

output "autoscaling_group_desired_capacity" {
  description = "Desired capacity of the Auto Scaling Group"
  value       = aws_autoscaling_group.main.desired_capacity
}

# Launch Template Outputs
output "launch_template_id" {
  description = "ID of the launch template"
  value       = aws_launch_template.main.id
}

output "launch_template_latest_version" {
  description = "Latest version of the launch template"
  value       = aws_launch_template.main.latest_version
}

# ALB Outputs
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.main.arn
}

output "alb_url" {
  description = "URL to access the application via ALB"
  value       = "http://${aws_lb.main.dns_name}"
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = aws_lb_target_group.main.arn
}

# CloudWatch Outputs
output "cloudwatch_dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "cloudwatch_dashboard_url" {
  description = "URL to the CloudWatch dashboard"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for CloudWatch alarms"
  value       = aws_sns_topic.alerts.arn
}

output "scaling_policies" {
  description = "Auto Scaling Policy ARNs"
  value = {
    target_tracking     = aws_autoscaling_policy.target_tracking_cpu.arn
    scale_out_aggressive = aws_autoscaling_policy.scale_out_aggressive.arn
    scale_in            = aws_autoscaling_policy.scale_in.arn
    emergency_scale_out = aws_autoscaling_policy.emergency_scale_out.arn
  }
}

output "cloudwatch_alarms" {
  description = "CloudWatch alarm names"
  value = {
    high_cpu               = aws_cloudwatch_metric_alarm.high_cpu.alarm_name
    emergency_cpu          = aws_cloudwatch_metric_alarm.emergency_cpu.alarm_name
    low_cpu                = aws_cloudwatch_metric_alarm.low_cpu.alarm_name
    high_network_in        = aws_cloudwatch_metric_alarm.high_network_in.alarm_name
    rapid_scaling_detection = aws_cloudwatch_metric_alarm.rapid_scaling_detection.alarm_name
  }
}

# Security Group Outputs
output "asg_security_group_id" {
  description = "ID of the ASG security group"
  value       = aws_security_group.asg.id
}

output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

# Test Configuration Outputs
output "scaling_test_info" {
  description = "Information for testing aggressive scaling"
  value = {
    scale_out_cpu_threshold   = var.scale_out_cpu_threshold
    emergency_cpu_threshold   = var.emergency_cpu_threshold
    rapid_scaling_threshold   = var.rapid_scaling_threshold
    max_instances             = var.asg_max_size
    scale_out_step_1          = var.scale_out_step_1
    scale_out_step_2          = var.scale_out_step_2
    scale_out_step_3          = var.scale_out_step_3
  }
}
