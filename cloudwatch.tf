# SNS Topic for CloudWatch Alarms
resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-cloudwatch-alerts"

  tags = {
    Name = "${var.project_name}-alerts"
  }
}

# SNS Topic Subscription (optional - configure email)
resource "aws_sns_topic_subscription" "alerts_email" {
  count = var.alert_email != "" ? 1 : 0

  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# CloudWatch Alarm - High CPU Utilization
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.project_name}-high-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.cpu_alarm_evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = var.cpu_alarm_period
  statistic           = "Average"
  threshold           = var.cpu_high_threshold
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = aws_instance.main.id
  }

  tags = {
    Name = "${var.project_name}-high-cpu-alarm"
  }
}

# CloudWatch Alarm - Low CPU Utilization
resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name          = "${var.project_name}-low-cpu-utilization"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = var.cpu_alarm_evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = var.cpu_alarm_period
  statistic           = "Average"
  threshold           = var.cpu_low_threshold
  alarm_description   = "This metric monitors ec2 low cpu utilization"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = aws_instance.main.id
  }

  tags = {
    Name = "${var.project_name}-low-cpu-alarm"
  }
}

# CloudWatch Alarm - High Network In
resource "aws_cloudwatch_metric_alarm" "high_network_in" {
  alarm_name          = "${var.project_name}-high-network-in"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.network_alarm_evaluation_periods
  metric_name         = "NetworkIn"
  namespace           = "AWS/EC2"
  period              = var.network_alarm_period
  statistic           = "Average"
  threshold           = var.network_in_high_threshold
  alarm_description   = "This metric monitors network traffic in"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = aws_instance.main.id
  }

  tags = {
    Name = "${var.project_name}-high-network-in-alarm"
  }
}

# CloudWatch Alarm - High Network Out
resource "aws_cloudwatch_metric_alarm" "high_network_out" {
  alarm_name          = "${var.project_name}-high-network-out"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.network_alarm_evaluation_periods
  metric_name         = "NetworkOut"
  namespace           = "AWS/EC2"
  period              = var.network_alarm_period
  statistic           = "Average"
  threshold           = var.network_out_high_threshold
  alarm_description   = "This metric monitors network traffic out"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = aws_instance.main.id
  }

  tags = {
    Name = "${var.project_name}-high-network-out-alarm"
  }
}

# CloudWatch Alarm - Instance Status Check Failed
resource "aws_cloudwatch_metric_alarm" "instance_health" {
  alarm_name          = "${var.project_name}-instance-status-check-failed"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  alarm_description   = "This metric monitors instance status checks"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = aws_instance.main.id
  }

  tags = {
    Name = "${var.project_name}-instance-health-alarm"
  }
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", { stat = "Average", InstanceId = aws_instance.main.id }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "EC2 CPU Utilization"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/EC2", "NetworkIn", { stat = "Average", InstanceId = aws_instance.main.id }],
            [".", "NetworkOut", { stat = "Average", InstanceId = aws_instance.main.id }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Network Traffic"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/EC2", "StatusCheckFailed", { stat = "Maximum", InstanceId = aws_instance.main.id }]
          ]
          period = 300
          stat   = "Maximum"
          region = var.aws_region
          title  = "Instance Status Check"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", { stat = "Average", LoadBalancer = aws_lb.main.arn_suffix }],
            [".", "RequestCount", { stat = "Sum", LoadBalancer = aws_lb.main.arn_suffix }]
          ]
          period = 300
          region = var.aws_region
          title  = "ALB Metrics"
        }
      }
    ]
  })
}
