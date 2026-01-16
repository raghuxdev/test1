# General Variables
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "ec2-scaling-test"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "test"
}

# Network Variables
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "Number of availability zones to use"
  type        = number
  default     = 2
}

# EC2 Variables
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "SSH key pair name for EC2 instance access"
  type        = string
  default     = ""
}

variable "root_volume_size" {
  description = "Size of root volume in GB"
  type        = number
  default     = 20
}

variable "ssh_allowed_ips" {
  description = "List of CIDR blocks allowed to SSH into EC2 instances"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# Auto Scaling Group Variables
variable "asg_min_size" {
  description = "Minimum number of instances in ASG"
  type        = number
  default     = 1
}

variable "asg_max_size" {
  description = "Maximum number of instances in ASG - HIGH for testing aggressive scaling"
  type        = number
  default     = 20
}

variable "asg_desired_capacity" {
  description = "Desired number of instances in ASG"
  type        = number
  default     = 2
}

# AGGRESSIVE SCALING POLICY VARIABLES - DESIGNED FOR TESTING
variable "target_cpu_utilization" {
  description = "Target CPU utilization for target tracking - LOW to trigger easily"
  type        = number
  default     = 30
}

variable "scale_out_cpu_threshold" {
  description = "CPU threshold to trigger scale out - LOW for easy testing"
  type        = number
  default     = 40
}

variable "emergency_cpu_threshold" {
  description = "CPU threshold to trigger emergency scale out"
  type        = number
  default     = 60
}

variable "scale_in_cpu_threshold" {
  description = "CPU threshold to trigger scale in"
  type        = number
  default     = 15
}

variable "scale_out_step_1" {
  description = "Number of instances to scale to when CPU is 0-10% above threshold"
  type        = number
  default     = 5
}

variable "scale_out_step_2" {
  description = "Number of instances to scale to when CPU is 10-20% above threshold"
  type        = number
  default     = 10
}

variable "scale_out_step_3" {
  description = "Number of instances to scale to when CPU is >20% above threshold"
  type        = number
  default     = 15
}

variable "emergency_scale_percentage" {
  description = "Percentage increase for emergency scaling"
  type        = number
  default     = 200
}

# Guardian Extension Detection Threshold
variable "rapid_scaling_threshold" {
  description = "Threshold for rapid scaling alarm - YOUR GUARDIAN EXTENSION SHOULD MONITOR THIS"
  type        = number
  default     = 8
}

# Network Alarm Variables
variable "network_in_threshold" {
  description = "Network In threshold for alarm (bytes)"
  type        = number
  default     = 5000000
}

# Alert Variables
variable "alert_email" {
  description = "Email address to receive CloudWatch alarm notifications"
  type        = string
  default     = ""
}
