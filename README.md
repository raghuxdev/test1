# AWS EC2 Scaling Infrastructure with Terraform

This Terraform configuration deploys a scalable AWS EC2 instance infrastructure with Application Load Balancer (ALB) and comprehensive CloudWatch monitoring.

## Architecture Overview

This infrastructure includes:

- **VPC**: Custom VPC with public subnets across multiple availability zones
- **EC2 Instance**: Single EC2 instance with CloudWatch agent
- **Application Load Balancer**: ALB for distributing traffic
- **CloudWatch Monitoring**: CPU and network traffic monitoring with alarms
- **SNS Notifications**: Email alerts for CloudWatch alarms
- **Security Groups**: Properly configured security groups for ALB and EC2

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.0
- An existing EC2 key pair for SSH access (or create one in AWS Console)
- Valid email address for CloudWatch alarm notifications

## Quick Start

### 1. Clone or Navigate to Repository

```bash
cd terraform-aws-ec2-scaling
```

### 2. Create Configuration File

Copy the example configuration and customize it:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your specific values:

```hcl
aws_region   = "us-east-1"
project_name = "my-ec2-app"
environment  = "production"

# EC2 Configuration
instance_type = "t3.micro"
key_name      = "your-key-pair-name"

# Alert Configuration
alert_email = "your-email@example.com"

# Optional: Restrict SSH access
ssh_allowed_ips = ["your.ip.address/32"]
```

### 3. Initialize Terraform

```bash
terraform init
```

### 4. Review Planned Changes

```bash
terraform plan
```

### 5. Deploy Infrastructure

```bash
terraform apply
```

Type `yes` when prompted to confirm deployment.

### 6. Confirm SNS Subscription

After deployment, check your email and confirm the SNS subscription to receive CloudWatch alarm notifications.

## Accessing Your Application

After successful deployment, Terraform will output the ALB DNS name:

```
alb_url = "http://ec2-scaling-alb-1234567890.us-east-1.elb.amazonaws.com"
```

Access your application using this URL in a web browser.

## CloudWatch Monitoring

### Alarms Configured

This infrastructure includes the following CloudWatch alarms:

1. **High CPU Utilization**: Triggers when CPU usage exceeds 80% (configurable)
2. **Low CPU Utilization**: Triggers when CPU usage falls below 20% (configurable)
3. **High Network In**: Triggers when network in exceeds threshold
4. **High Network Out**: Triggers when network out exceeds threshold
5. **Instance Status Check**: Triggers when instance status checks fail

### CloudWatch Dashboard

A CloudWatch dashboard is automatically created with metrics for:

- EC2 CPU Utilization
- Network Traffic (In/Out)
- Instance Status Checks
- ALB Response Time and Request Count

Access the dashboard in AWS Console: CloudWatch → Dashboards → `{project_name}-dashboard`

### Customizing Alarm Thresholds

Modify these variables in `terraform.tfvars`:

```hcl
# CPU Thresholds (percentage)
cpu_high_threshold = 80
cpu_low_threshold  = 20

# Network Thresholds (bytes)
network_in_high_threshold  = 10000000
network_out_high_threshold = 10000000

# Evaluation Settings
cpu_alarm_period             = 300  # 5 minutes
cpu_alarm_evaluation_periods = 2
```

## SSH Access to EC2 Instance

To SSH into the EC2 instance:

```bash
# Get the instance public IP from Terraform output
terraform output instance_public_ip

# SSH into the instance
ssh -i /path/to/your-key.pem ec2-user@<instance_public_ip>
```

## Scaling Considerations

### Current Setup (Single Instance)

This configuration deploys a single EC2 instance. For manual scaling:

1. Modify `instance_type` in `terraform.tfvars` to a larger instance type
2. Run `terraform apply` to update the instance

### Upgrading to Auto Scaling

To implement auto-scaling based on CloudWatch metrics:

1. Replace the single EC2 instance with an Auto Scaling Group (ASG)
2. Create a Launch Template
3. Add Auto Scaling Policies based on CloudWatch alarms
4. Update the ALB target group to use the ASG

## Cost Optimization

Estimated monthly costs (us-east-1):

- t3.micro EC2 instance: ~$7.50/month
- Application Load Balancer: ~$16.20/month
- Data transfer and CloudWatch: Variable
- **Total**: ~$25-30/month

To reduce costs:

- Use `t3.micro` or `t3.nano` for development
- Remove ALB if not needed (access EC2 directly)
- Reduce CloudWatch alarm frequency
- Stop instances during non-business hours

## Outputs

After deployment, the following outputs are available:

```bash
terraform output
```

Key outputs:

- `alb_url`: URL to access your application
- `instance_id`: EC2 instance ID
- `instance_public_ip`: Public IP of EC2 instance
- `cloudwatch_dashboard_name`: Name of the CloudWatch dashboard
- `cloudwatch_alarms`: List of all alarm names

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

Type `yes` when prompted to confirm destruction.

## File Structure

```
terraform-aws-ec2-scaling/
├── main.tf                      # Provider and data sources
├── vpc.tf                       # VPC and networking resources
├── security_groups.tf           # Security group configurations
├── ec2.tf                       # EC2 instance and IAM resources
├── alb.tf                       # Application Load Balancer setup
├── cloudwatch.tf                # CloudWatch alarms and dashboard
├── variables.tf                 # Variable definitions
├── outputs.tf                   # Output definitions
├── terraform.tfvars.example     # Example configuration
└── README.md                    # This file
```

## Security Best Practices

1. **SSH Access**: Restrict `ssh_allowed_ips` to your specific IP address
2. **Key Management**: Never commit your SSH private keys or `terraform.tfvars` to version control
3. **Encryption**: Root volumes are encrypted by default
4. **IAM Roles**: EC2 instance uses IAM role instead of access keys
5. **HTTPS**: Consider adding SSL certificate to ALB for production use

## Troubleshooting

### Instance Not Responding

1. Check instance status: `aws ec2 describe-instance-status --instance-ids <instance-id>`
2. Review CloudWatch logs
3. Check security group rules
4. Verify user data script execution: `sudo cat /var/log/cloud-init-output.log`

### ALB Health Check Failing

1. Verify EC2 instance is running and accepting traffic on port 80
2. Check security group allows traffic from ALB
3. Review target group health check settings
4. Check application logs: `sudo tail -f /var/log/httpd/error_log`

### CloudWatch Alarms Not Triggering

1. Verify SNS subscription is confirmed
2. Check alarm threshold settings
3. Review CloudWatch metrics: AWS Console → CloudWatch → Metrics
4. Ensure EC2 detailed monitoring is enabled

## Contributing

Feel free to submit issues and enhancement requests.

## License

This project is open source and available under the MIT License.
