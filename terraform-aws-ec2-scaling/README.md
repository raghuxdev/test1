# AWS EC2 Auto Scaling Test Configuration

This Terraform configuration creates an **AGGRESSIVE** auto scaling setup designed specifically for **testing auto scaling guardian extensions**. The configuration is intentionally set with low thresholds and high scaling increments to easily trigger rapid scaling events.

## Purpose

This infrastructure is built to test auto scaling guardian/monitoring extensions that detect when upscaling exceeds safe thresholds. The configuration includes:

- **Low CPU thresholds** (40% to trigger scaling, 60% for emergency)
- **Aggressive step scaling** (jumps to 5, 10, or 15 instances based on load)
- **High max capacity** (up to 20 instances)
- **Rapid scaling alarm** (triggers when capacity exceeds 8 instances)
- **Multiple scaling policies** that can compound effects

## Architecture

- **Auto Scaling Group**: 1-20 instances with aggressive scaling policies
- **Application Load Balancer**: Distributes traffic across instances
- **VPC**: Custom VPC with multi-AZ public subnets
- **CloudWatch Monitoring**: Comprehensive metrics and alarms
- **SNS Notifications**: Email alerts for all scaling events

## Scaling Behavior

### Normal Scaling (Target Tracking)
- Maintains CPU at 30% utilization
- Gradually adds/removes instances

### Step Scaling (Aggressive)
When CPU exceeds 40%:
- **40-50% CPU**: Scales to 5 instances
- **50-60% CPU**: Scales to 10 instances
- **>60% CPU**: Scales to 15 instances

### Emergency Scaling
When CPU exceeds 60%:
- Increases capacity by 200% (doubles current size)
- Can trigger simultaneously with step scaling

### Guardian Detection Point
- **Rapid Scaling Alarm**: Triggers when desired capacity > 8 instances
- **Your extension should monitor this alarm and the ASG metrics**

## Quick Start

### 1. Prerequisites

- AWS CLI configured
- Terraform >= 1.0
- EC2 key pair (optional, for SSH access)
- Email for alarm notifications

### 2. Configure

```bash
cd terraform-aws-ec2-scaling
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:
```hcl
aws_region   = "us-east-1"
project_name = "scaling-test"
key_name     = "your-key-pair"
alert_email  = "your-email@example.com"
```

### 3. Deploy

```bash
terraform init
terraform plan
terraform apply
```

### 4. Test Aggressive Scaling

After deployment, you have several options to trigger scaling:

#### Option A: Generate CPU Load via SSH

1. Get an instance IP from AWS Console or CLI
2. SSH into any instance:
   ```bash
   ssh -i your-key.pem ec2-user@<instance-ip>
   ```
3. Run the load test script:
   ```bash
   sudo /usr/local/bin/load-test.sh
   ```
   This generates CPU load for 5 minutes using all cores.

#### Option B: Use AWS CLI to Generate Load

```bash
# Get instance IDs
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names ec2-scaling-test-asg \
  --query 'AutoScalingGroups[0].Instances[*].InstanceId' \
  --output text

# SSH and run stress test on multiple instances
for instance in <instance-ids>; do
  ssh -i your-key.pem ec2-user@$(aws ec2 describe-instances \
    --instance-ids $instance \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text) \
    'sudo /usr/local/bin/load-test.sh' &
done
```

#### Option C: Use AWS Systems Manager (No SSH Required)

```bash
# Get ASG instances
ASG_NAME="ec2-scaling-test-asg"

# Send command to all instances
aws ssm send-command \
  --document-name "AWS-RunShellScript" \
  --targets "Key=tag:aws:autoscaling:groupName,Values=$ASG_NAME" \
  --parameters 'commands=["stress --cpu $(nproc) --timeout 300s"]'
```

## Monitoring Scaling Events

### CloudWatch Dashboard
Access your dashboard:
```
https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=ec2-scaling-test-dashboard
```

The dashboard shows:
- **ASG Capacity Metrics**: Desired, in-service, min, max
- **CPU Utilization**: With threshold annotations
- **Network Traffic**: In/out bytes
- **ALB Metrics**: Response time, request count, healthy hosts

### Watch Scaling in Real-Time

```bash
# Watch ASG capacity
watch -n 5 'aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names ec2-scaling-test-asg \
  --query "AutoScalingGroups[0].[DesiredCapacity,MinSize,MaxSize]" \
  --output table'

# Watch scaling activities
aws autoscaling describe-scaling-activities \
  --auto-scaling-group-name ec2-scaling-test-asg \
  --max-records 20
```

### CloudWatch Alarms

Monitor these alarms (they'll also email you):
- `ec2-scaling-test-high-cpu-utilization`: Triggers scale out
- `ec2-scaling-test-emergency-cpu-utilization`: Triggers emergency scaling
- `ec2-scaling-test-rapid-scaling-detection`: **YOUR GUARDIAN EXTENSION TARGET**

## Testing Your Guardian Extension

Your guardian extension should monitor:

1. **ASG Desired Capacity Metric**
   - Namespace: `AWS/AutoScaling`
   - Metric: `GroupDesiredCapacity`
   - Threshold: > 8 instances (configurable via `rapid_scaling_threshold`)

2. **Scaling Activities**
   - Monitor via AWS API: `describe-scaling-activities`
   - Look for rapid successive scaling events

3. **Rate of Change**
   - Track how quickly capacity increases
   - Alert on scaling velocity (e.g., +5 instances in 2 minutes)

4. **CloudWatch Alarm Integration**
   - Subscribe to the `rapid-scaling-detection` alarm
   - Or create your own alarms based on ASG metrics

### Expected Behavior for Testing

When you trigger high CPU load:

1. **T+0:00**: CPU rises above 40%
2. **T+0:01**: `high-cpu-utilization` alarm triggers
3. **T+0:01**: Step scaling policy activates, scales to 5-15 instances
4. **T+0:01**: `rapid-scaling-detection` alarm triggers (capacity > 8)
5. **T+0:02**: Your guardian extension should detect this event
6. **T+0:02**: If CPU continues high, target tracking also adds instances
7. **T+0:03**: Possible emergency scaling if CPU > 60%

This creates a scenario where your guardian can detect "runaway" scaling.

## Configuration Tuning

Adjust these variables in `terraform.tfvars` to change behavior:

```hcl
# Make scaling even more aggressive
scale_out_step_1 = 8   # Jump to 8 instances immediately
scale_out_step_2 = 15  # Jump to 15 at medium load
scale_out_step_3 = 20  # Max out at high load

# Lower thresholds to trigger easier
scale_out_cpu_threshold = 30  # Scale at 30% CPU
target_cpu_utilization = 20   # Target 20% CPU

# Change guardian detection threshold
rapid_scaling_threshold = 5   # Alert at 5 instances instead of 8
```

## Cost Warning

This configuration can scale to **20 t3.micro instances** plus an ALB.

**Estimated costs if running at max scale:**
- 20 × t3.micro: ~$0.30/hour = $6/hour
- ALB: ~$0.025/hour
- **Total: ~$6-7/hour when fully scaled**

**Cost control:**
- Set `asg_max_size = 5` to limit max instances
- Scale down quickly with low `scale_in_cpu_threshold`
- Destroy infrastructure when not testing: `terraform destroy`

## Cleanup

```bash
terraform destroy
```

Type `yes` to confirm removal of all resources.

## File Structure

```
terraform-aws-ec2-scaling/
├── main.tf                 # Provider and data sources
├── vpc.tf                  # VPC and networking
├── security_groups.tf      # Security groups for ALB and ASG
├── autoscaling.tf          # ASG, launch template, scaling policies
├── alb.tf                  # Application Load Balancer
├── cloudwatch.tf           # Alarms, dashboard, SNS
├── variables.tf            # Variable definitions
├── outputs.tf              # Output values
├── terraform.tfvars.example # Example configuration
└── README.md               # This file
```

## Troubleshooting

### Scaling Not Triggering

1. Check CPU utilization is actually increasing:
   ```bash
   aws cloudwatch get-metric-statistics \
     --namespace AWS/EC2 \
     --metric-name CPUUtilization \
     --dimensions Name=AutoScalingGroupName,Value=ec2-scaling-test-asg \
     --start-time $(date -u -d '10 minutes ago' +%Y-%m-%dT%H:%M:%S) \
     --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
     --period 60 \
     --statistics Average
   ```

2. Verify alarms are enabled:
   ```bash
   aws cloudwatch describe-alarms \
     --alarm-name-prefix ec2-scaling-test
   ```

3. Check scaling activities for errors:
   ```bash
   aws autoscaling describe-scaling-activities \
     --auto-scaling-group-name ec2-scaling-test-asg \
     --max-records 10
   ```

### Instances Not Launching

1. Check service quotas (EC2 instance limits)
2. Verify subnets have available IPs
3. Review CloudWatch Logs for ASG events

### Scaling Too Aggressive

Reduce scaling increments:
```hcl
scale_out_step_1 = 3
scale_out_step_2 = 5
scale_out_step_3 = 8
```

## Integration with Guardian Extensions

Example integration points for your guardian extension:

### CloudWatch Events
Subscribe to Auto Scaling events via EventBridge:
```json
{
  "source": ["aws.autoscaling"],
  "detail-type": ["EC2 Instance Launch Successful"],
  "detail": {
    "AutoScalingGroupName": ["ec2-scaling-test-asg"]
  }
}
```

### SNS Subscription
Subscribe your guardian to the SNS topic:
```bash
aws sns subscribe \
  --topic-arn <sns-topic-arn> \
  --protocol https \
  --notification-endpoint https://your-guardian-extension.com/webhook
```

### CloudWatch Metrics Query
Poll ASG metrics programmatically:
```python
import boto3

cloudwatch = boto3.client('cloudwatch')
response = cloudwatch.get_metric_statistics(
    Namespace='AWS/AutoScaling',
    MetricName='GroupDesiredCapacity',
    Dimensions=[{'Name': 'AutoScalingGroupName', 'Value': 'ec2-scaling-test-asg'}],
    StartTime=datetime.utcnow() - timedelta(minutes=5),
    EndTime=datetime.utcnow(),
    Period=60,
    Statistics=['Maximum']
)
```

## License

MIT License - Use freely for testing.
