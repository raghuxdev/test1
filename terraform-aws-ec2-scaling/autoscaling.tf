# IAM Role for EC2 Instances
resource "aws_iam_role" "asg" {
  name_prefix = "${var.project_name}-asg-role-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-asg-role"
  }
}

resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.asg.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "asg" {
  name_prefix = "${var.project_name}-asg-profile-"
  role        = aws_iam_role.asg.name

  tags = {
    Name = "${var.project_name}-asg-profile"
  }
}

# Launch Template for Auto Scaling Group
resource "aws_launch_template" "main" {
  name_prefix   = "${var.project_name}-lt-"
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = var.instance_type
  key_name      = var.key_name

  iam_instance_profile {
    arn = aws_iam_instance_profile.asg.arn
  }

  vpc_security_group_ids = [aws_security_group.asg.id]

  monitoring {
    enabled = true
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd stress

              # Install CloudWatch agent
              wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
              rpm -U ./amazon-cloudwatch-agent.rpm

              # Start web server
              systemctl start httpd
              systemctl enable httpd

              # Create a web page that generates CPU load
              cat > /var/www/html/index.html <<'HTML'
              <!DOCTYPE html>
              <html>
              <head>
                  <title>Auto Scaling Test</title>
              </head>
              <body>
                  <h1>Auto Scaling Group Instance</h1>
                  <p>Instance ID: $(ec2-metadata --instance-id | cut -d " " -f 2)</p>
                  <p>Availability Zone: $(ec2-metadata --availability-zone | cut -d " " -f 2)</p>
                  <p>This instance is part of an auto scaling group for testing</p>
              </body>
              </html>
              HTML

              # Create a script to generate CPU load for testing
              cat > /usr/local/bin/load-test.sh <<'SCRIPT'
              #!/bin/bash
              # Generate CPU load - run: sudo /usr/local/bin/load-test.sh
              stress --cpu $(nproc) --timeout 300s
              SCRIPT
              chmod +x /usr/local/bin/load-test.sh
              EOF
  )

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = var.root_volume_size
      volume_type           = "gp3"
      delete_on_termination = true
      encrypted             = true
    }
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${var.project_name}-asg-instance"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "main" {
  name                = "${var.project_name}-asg"
  vpc_zone_identifier = aws_subnet.public[*].id
  target_group_arns   = [aws_lb_target_group.main.arn]
  health_check_type   = "ELB"
  health_check_grace_period = 300

  min_size         = var.asg_min_size
  max_size         = var.asg_max_size
  desired_capacity = var.asg_desired_capacity

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances"
  ]

  tag {
    key                 = "Name"
    value               = "${var.project_name}-asg-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = var.project_name
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# AGGRESSIVE SCALING POLICIES FOR TESTING
# These policies are designed to trigger rapid scaling for guardian extension testing

# Target Tracking Scaling Policy - Aggressive CPU Targeting
resource "aws_autoscaling_policy" "target_tracking_cpu" {
  name                   = "${var.project_name}-target-tracking-cpu"
  autoscaling_group_name = aws_autoscaling_group.main.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    # AGGRESSIVE: Target very low CPU to trigger rapid scaling
    target_value = var.target_cpu_utilization
  }
}

# Step Scaling Policy - Scale Out (AGGRESSIVE)
resource "aws_autoscaling_policy" "scale_out_aggressive" {
  name                   = "${var.project_name}-scale-out-aggressive"
  autoscaling_group_name = aws_autoscaling_group.main.name
  adjustment_type        = "ExactCapacity"
  policy_type            = "StepScaling"

  step_adjustment {
    scaling_adjustment          = var.scale_out_step_1
    metric_interval_lower_bound = 0
    metric_interval_upper_bound = 10
  }

  step_adjustment {
    scaling_adjustment          = var.scale_out_step_2
    metric_interval_lower_bound = 10
    metric_interval_upper_bound = 20
  }

  step_adjustment {
    scaling_adjustment          = var.scale_out_step_3
    metric_interval_lower_bound = 20
  }
}

# Step Scaling Policy - Scale In
resource "aws_autoscaling_policy" "scale_in" {
  name                   = "${var.project_name}-scale-in"
  autoscaling_group_name = aws_autoscaling_group.main.name
  adjustment_type        = "ChangeInCapacity"
  policy_type            = "StepScaling"

  step_adjustment {
    scaling_adjustment          = -1
    metric_interval_upper_bound = 0
  }
}

# Simple Scaling Policy - Emergency Scale Out
resource "aws_autoscaling_policy" "emergency_scale_out" {
  name                   = "${var.project_name}-emergency-scale-out"
  autoscaling_group_name = aws_autoscaling_group.main.name
  adjustment_type        = "PercentChangeInCapacity"
  scaling_adjustment     = var.emergency_scale_percentage
  cooldown               = 60

  # This will add instances quickly when triggered
}
