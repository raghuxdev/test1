# TEST FILE FOR GUARDIAN EXTENSION
# This file uses HARDCODED instance types instead of variables
# Your parser will be able to detect changes in this file

resource "aws_iam_role" "asg_test" {
  name_prefix = "${var.project_name}-asg-test-role-"

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
    Name = "${var.project_name}-asg-test-role"
  }
}

resource "aws_iam_instance_profile" "asg_test" {
  name_prefix = "${var.project_name}-asg-test-profile-"
  role        = aws_iam_role.asg_test.name

  tags = {
    Name = "${var.project_name}-asg-test-profile"
  }
}

# HARDCODED INSTANCE TYPE - Easy to test parser
resource "aws_launch_template" "test_hardcoded" {
  name_prefix   = "${var.project_name}-test-lt-"
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = "t3.micro"  # HARDCODED - change this to test your parser
  key_name      = var.key_name

  iam_instance_profile {
    arn = aws_iam_instance_profile.asg_test.arn
  }

  vpc_security_group_ids = [aws_security_group.asg.id]

  monitoring {
    enabled = true
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              EOF
  )

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = 20
      volume_type           = "gp3"
      delete_on_termination = true
      encrypted             = true
    }
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${var.project_name}-asg-test-instance"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# HARDCODED INSTANCE TYPE - Another example
resource "aws_instance" "standalone_test" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t3.small"  # HARDCODED - change this to test your parser
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.asg.id]
  iam_instance_profile   = aws_iam_instance_profile.asg_test.name
  key_name               = var.key_name

  monitoring = true

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              EOF

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true
  }

  tags = {
    Name = "${var.project_name}-standalone-test"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group using the hardcoded launch template
resource "aws_autoscaling_group" "test_hardcoded" {
  name                = "${var.project_name}-asg-test"
  vpc_zone_identifier = aws_subnet.public[*].id
  health_check_type   = "EC2"
  health_check_grace_period = 300

  min_size         = 1
  max_size         = 10
  desired_capacity = 2

  launch_template {
    id      = aws_launch_template.test_hardcoded.id
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
    value               = "${var.project_name}-asg-test-instance"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}
