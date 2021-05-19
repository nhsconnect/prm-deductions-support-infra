locals {
  prefix = var.prefix == "" ? "" : "${var.prefix}-"
}

# S3 bucket to hold terraform states of other repos
resource "aws_s3_bucket" "prm-deductions-terraform-state" {
  bucket = "prm-deductions-${local.prefix}terraform-state"
  acl    = "private"

  # To allow rolling back states
  versioning {
    enabled = true
  }

  # To cleanup old states eventually
  lifecycle_rule {
    enabled = true

    noncurrent_version_expiration {
      days = 360
    }
  }

  tags = {
     Name = "Terraform states of deductions infrastructure"
     CreatedBy = "prm-deductions-support-infra"
  }
}

# S3 bucket to hold terraform state produced in this repo
resource "aws_s3_bucket" "prm-deductions-terraform-state-store" {
  bucket = "prm-deductions-${local.prefix}terraform-state-store"
  acl    = "private"

  # To allow rolling back states
  versioning {
    enabled = true
  }

  # To cleanup old states eventually
  lifecycle_rule {
    enabled = true

    noncurrent_version_expiration {
      days = 360
    }
  }

  tags = {
     Name = "Terraform state of the prm-deductions-support-infra"
     CreatedBy = "prm-deductions-support-infra"
  }
}

output "state_store" {
  value = "prm-deductions-${local.prefix}terraform-state-store"
}
