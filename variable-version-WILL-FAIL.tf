# Modified version - This will FAIL the policy check
# This file uses variables which cannot be evaluated

resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = var.instance_type  # ❌ VARIABLE: Cannot evaluate (WILL FAIL)

  tags = {
    Name = "web-server"
  }
}

resource "aws_launch_template" "api" {
  name_prefix   = "api-server-"
  image_id      = "ami-0c55b159cbfafe1f0"
  instance_type = var.api_instance_type  # ❌ VARIABLE: Cannot evaluate (WILL FAIL)

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "api-server"
    }
  }
}

resource "aws_autoscaling_group" "workers" {
  name                = "worker-asg"
  vpc_zone_identifier = ["subnet-12345"]
  min_size            = 1
  max_size            = 3
  desired_capacity    = 2

  launch_template {
    id      = aws_launch_template.workers_lt.id
    version = "$Latest"
  }
}

resource "aws_launch_template" "workers_lt" {
  name_prefix   = "workers-lt-"
  image_id      = "ami-0c55b159cbfafe1f0"
  instance_type = local.worker_instance_type  # ❌ LOCAL: Cannot evaluate (WILL FAIL)

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "worker-instance"
    }
  }
}
