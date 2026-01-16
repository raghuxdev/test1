# General Variables
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "ec2-scaling"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
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

# CloudWatch Alarm Variables - CPU
variable "cpu_high_threshold" {
  description = "CPU utilization threshold for high alarm (percentage)"
  type        = number
  default     = 80
}

variable "cpu_low_threshold" {
  description = "CPU utilization threshold for low alarm (percentage)"
  type        = number
  default     = 20
}

variable "cpu_alarm_period" {
  description = "Period in seconds for CPU alarm evaluation"
  type        = number
  default     = 300
}

variable "cpu_alarm_evaluation_periods" {
  description = "Number of periods for CPU alarm evaluation"
  type        = number
  default     = 2
}

# CloudWatch Alarm Variables - Network
variable "network_in_high_threshold" {
  description = "Network In threshold for high alarm (bytes)"
  type        = number
  default     = 10000000
}

variable "network_out_high_threshold" {
  description = "Network Out threshold for high alarm (bytes)"
  type        = number
  default     = 10000000
}

variable "network_alarm_period" {
  description = "Period in seconds for network alarm evaluation"
  type        = number
  default     = 300
}

variable "network_alarm_evaluation_periods" {
  description = "Number of periods for network alarm evaluation"
  type        = number
  default     = 2
}

# Alert Variables
variable "alert_email" {
  description = "Email address to receive CloudWatch alarm notifications"
  type        = string
  default     = ""
}
