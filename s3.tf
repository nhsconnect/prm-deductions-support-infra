locals {
  prefix = var.prefix == "" ? "" : "${var.prefix}-"
}

# S3 bucket to hold terraform states of other repos
resource "aws_s3_bucket" "prm_deductions_terraform_state" {
  bucket = "prm-deductions-${local.prefix}terraform-state"

  tags = {
     Name = "Terraform states of deductions infrastructure"
     CreatedBy = "prm-deductions-support-infra"
  }
}

resource "aws_s3_bucket_acl" "prm_deductions_bucket_acl" {
  bucket = aws_s3_bucket.prm_deductions_terraform_state.id
  acl    = "private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "prm_deductions_server_side_encryption" {
  bucket = aws_s3_bucket.prm_deductions_terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "prm_deductions_versioning" {
  bucket = aws_s3_bucket.prm_deductions_terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "prm_deductions_lifecycle_config" {
  bucket = aws_s3_bucket.prm_deductions_terraform_state.id

  rule {
    id     = "Expiration life cycle rule"
    status = "Enabled"


    noncurrent_version_expiration {
      noncurrent_days = 360
    }
  }
}


resource "aws_s3_bucket_policy" "terraform-state" {
  bucket = aws_s3_bucket.prm_deductions_terraform_state.id
  policy = jsonencode({
    "Statement": [
      {
        Effect: "Deny",
        Principal: "*",
        Action: "s3:*",
        Resource: "${aws_s3_bucket.prm_deductions_terraform_state.arn}/*",
        Condition: {
          Bool: {
            "aws:SecureTransport": "false"
          }
        }
      }
    ]
  })
}

# S3 bucket to hold terraform state produced in this repo
resource "aws_s3_bucket" "prm_deductions_terraform_state_store" {
  bucket = "prm-deductions-${local.prefix}terraform-state-store"

  tags = {
     Name = "Terraform state of the prm-deductions-support-infra"
     CreatedBy = "prm-deductions-support-infra"
  }
}

resource "aws_s3_bucket_acl" "prm_deductions_state_store_bucket_acl" {
  bucket = aws_s3_bucket.prm_deductions_terraform_state_store.id
  acl    = "private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "prm_deductions_state_store_server_side_encryption" {
  bucket = aws_s3_bucket.prm_deductions_terraform_state_store.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "prm_deductions_state_store_versioning" {
  bucket = aws_s3_bucket.prm_deductions_terraform_state_store.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "prm_deductions_state_store_lifecycle_config" {
  bucket = aws_s3_bucket.prm_deductions_terraform_state_store.id

  rule {
    id     = "Expiration life cycle rule"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 360
    }
  }
}

resource "aws_s3_bucket_policy" "terraform-state-store" {
  bucket = aws_s3_bucket.prm_deductions_terraform_state_store.id
  policy = jsonencode({
    "Statement": [
      {
        Effect: "Deny",
        Principal: "*",
        Action: "s3:*",
        Resource: "${aws_s3_bucket.prm_deductions_terraform_state_store.arn}/*",
        Condition: {
          Bool: {
            "aws:SecureTransport": "false"
          }
        }
      }
    ]
  })
}
