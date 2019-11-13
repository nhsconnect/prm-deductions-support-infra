
_push:
	aws s3 cp terraform.tfstate s3://prm-deductions-terraform-state-store/terraform.tfstate

_pull:
	aws s3 cp s3://prm-deductions-terraform-state-store/terraform.tfstate terraform.tfstate

_apply:
	terraform init
	terraform apply
