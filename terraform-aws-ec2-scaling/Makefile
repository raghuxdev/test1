.PHONY: help init plan apply destroy validate fmt clean watch-asg trigger-load

help:
	@echo "Available commands:"
	@echo "  make init         - Initialize Terraform"
	@echo "  make plan         - Show Terraform execution plan"
	@echo "  make apply        - Apply Terraform configuration"
	@echo "  make destroy      - Destroy infrastructure"
	@echo "  make validate     - Validate Terraform configuration"
	@echo "  make fmt          - Format Terraform files"
	@echo "  make clean        - Clean Terraform files"
	@echo "  make watch-asg    - Watch Auto Scaling Group capacity in real-time"
	@echo "  make watch-alarms - Watch CloudWatch alarms status"

init:
	terraform init

plan:
	terraform plan

apply:
	terraform apply

destroy:
	terraform destroy

validate:
	terraform validate

fmt:
	terraform fmt -recursive

clean:
	rm -rf .terraform
	rm -f .terraform.lock.hcl
	rm -f terraform.tfstate*
	rm -f tfplan

watch-asg:
	@echo "Watching Auto Scaling Group capacity (Ctrl+C to stop)..."
	@watch -n 5 'aws autoscaling describe-auto-scaling-groups \
		--auto-scaling-group-names $$(terraform output -raw autoscaling_group_name 2>/dev/null || echo "ec2-scaling-test-asg") \
		--query "AutoScalingGroups[0].[DesiredCapacity,MinSize,MaxSize,\"---\"] | @tsv" \
		--output text && \
		aws autoscaling describe-auto-scaling-groups \
		--auto-scaling-group-names $$(terraform output -raw autoscaling_group_name 2>/dev/null || echo "ec2-scaling-test-asg") \
		--query "AutoScalingGroups[0].Instances[*].[InstanceId,LifecycleState,HealthStatus] | @tsv" \
		--output text'

watch-alarms:
	@echo "Watching CloudWatch alarms (Ctrl+C to stop)..."
	@watch -n 10 'aws cloudwatch describe-alarms \
		--alarm-name-prefix $$(terraform output -json | jq -r ".project_name.value" 2>/dev/null || echo "ec2-scaling-test") \
		--query "MetricAlarms[*].[AlarmName,StateValue] | @tsv" \
		--output text'
