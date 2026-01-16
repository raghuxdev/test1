.PHONY: help init plan apply destroy validate fmt clean

help:
	@echo "Available commands:"
	@echo "  make init      - Initialize Terraform"
	@echo "  make plan      - Show Terraform execution plan"
	@echo "  make apply     - Apply Terraform configuration"
	@echo "  make destroy   - Destroy Terraform-managed infrastructure"
	@echo "  make validate  - Validate Terraform configuration"
	@echo "  make fmt       - Format Terraform files"
	@echo "  make clean     - Clean Terraform files"

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
