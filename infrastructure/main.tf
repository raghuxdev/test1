# Base version - This should be committed to main branch first
# This file uses t2.micro instance type

resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"  # Small instance

  tags = {
    Name = "web-server"
  }
}

resource "aws_launch_template" "api" {
  name_prefix   = "api-server-"
  image_id      = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.small"  # Starting with small

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
  instance_type = "t3.micro"  # Burstable instance

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "worker-instance"
    }
  }
}
