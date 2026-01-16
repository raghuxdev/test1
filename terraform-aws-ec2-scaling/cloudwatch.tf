# SNS Topic for CloudWatch Alarms
resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-cloudwatch-alerts"

  tags = {
    Name = "${var.project_name}-alerts"
  }
}

resource "aws_sns_topic_subscription" "alerts_email" {
  count = var.alert_email != "" ? 1 : 0

  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# AGGRESSIVE CLOUDWATCH ALARMS FOR TESTING
# These have LOW thresholds to trigger scaling easily

# High CPU Alarm - Triggers Aggressive Scale Out
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.project_name}-high-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = var.scale_out_cpu_threshold
  alarm_description   = "Triggers aggressive scale out when CPU is high"
  alarm_actions       = [
    aws_sns_topic.alerts.arn,
    aws_autoscaling_policy.scale_out_aggressive.arn
  ]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.main.name
  }

  tags = {
    Name = "${var.project_name}-high-cpu-alarm"
  }
}

# Emergency High CPU Alarm - Triggers Emergency Scale Out
resource "aws_cloudwatch_metric_alarm" "emergency_cpu" {
  alarm_name          = "${var.project_name}-emergency-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = var.emergency_cpu_threshold
  alarm_description   = "Triggers emergency scale out when CPU is critically high"
  alarm_actions       = [
    aws_sns_topic.alerts.arn,
    aws_autoscaling_policy.emergency_scale_out.arn
  ]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.main.name
  }

  tags = {
    Name = "${var.project_name}-emergency-cpu-alarm"
  }
}

# Low CPU Alarm - Triggers Scale In
resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name          = "${var.project_name}-low-cpu-utilization"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = var.scale_in_cpu_threshold
  alarm_description   = "Triggers scale in when CPU is low"
  alarm_actions       = [
    aws_sns_topic.alerts.arn,
    aws_autoscaling_policy.scale_in.arn
  ]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.main.name
  }

  tags = {
    Name = "${var.project_name}-low-cpu-alarm"
  }
}

# High Network In Alarm
resource "aws_cloudwatch_metric_alarm" "high_network_in" {
  alarm_name          = "${var.project_name}-high-network-in"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "NetworkIn"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = var.network_in_threshold
  alarm_description   = "Monitors high network traffic in"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.main.name
  }

  tags = {
    Name = "${var.project_name}-high-network-in-alarm"
  }
}

# ASG Capacity Alarm - Detects Rapid Scaling
resource "aws_cloudwatch_metric_alarm" "rapid_scaling_detection" {
  alarm_name          = "${var.project_name}-rapid-scaling-detection"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "GroupDesiredCapacity"
  namespace           = "AWS/AutoScaling"
  period              = 60
  statistic           = "Maximum"
  threshold           = var.rapid_scaling_threshold
  alarm_description   = "Detects when ASG scales beyond threshold - YOUR GUARDIAN EXTENSION SHOULD CATCH THIS"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.main.name
  }

  tags = {
    Name = "${var.project_name}-rapid-scaling-alarm"
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
            ["AWS/AutoScaling", "GroupDesiredCapacity", { stat = "Average", AutoScalingGroupName = aws_autoscaling_group.main.name }],
            [".", "GroupInServiceInstances", { stat = "Average", AutoScalingGroupName = aws_autoscaling_group.main.name }],
            [".", "GroupMinSize", { stat = "Average", AutoScalingGroupName = aws_autoscaling_group.main.name }],
            [".", "GroupMaxSize", { stat = "Average", AutoScalingGroupName = aws_autoscaling_group.main.name }]
          ]
          period = 60
          stat   = "Average"
          region = var.aws_region
          title  = "Auto Scaling Group Metrics"
          yAxis = {
            left = {
              min = 0
            }
          }
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", { stat = "Average", AutoScalingGroupName = aws_autoscaling_group.main.name }]
          ]
          period = 60
          stat   = "Average"
          region = var.aws_region
          title  = "Average CPU Utilization"
          annotations = {
            horizontal = [
              {
                label  = "Scale Out Threshold"
                value  = var.scale_out_cpu_threshold
                color  = "#ff0000"
              },
              {
                label  = "Emergency Threshold"
                value  = var.emergency_cpu_threshold
                color  = "#990000"
              },
              {
                label  = "Scale In Threshold"
                value  = var.scale_in_cpu_threshold
                color  = "#00ff00"
              }
            ]
          }
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/EC2", "NetworkIn", { stat = "Average", AutoScalingGroupName = aws_autoscaling_group.main.name }],
            [".", "NetworkOut", { stat = "Average", AutoScalingGroupName = aws_autoscaling_group.main.name }]
          ]
          period = 60
          stat   = "Average"
          region = var.aws_region
          title  = "Network Traffic"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", { stat = "Average", LoadBalancer = aws_lb.main.arn_suffix }],
            [".", "RequestCount", { stat = "Sum", LoadBalancer = aws_lb.main.arn_suffix }],
            [".", "HealthyHostCount", { stat = "Average", TargetGroup = aws_lb_target_group.main.arn_suffix, LoadBalancer = aws_lb.main.arn_suffix }]
          ]
          period = 60
          region = var.aws_region
          title  = "ALB Metrics"
        }
      }
    ]
  })
}
