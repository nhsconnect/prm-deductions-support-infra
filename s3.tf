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

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = {
     Name = "Terraform states of deductions infrastructure"
     CreatedBy = "prm-deductions-support-infra"
  }
}

resource "aws_s3_bucket_policy" "terraform-state" {
  bucket = aws_s3_bucket.prm-deductions-terraform-state.id
  policy = jsonencode({
    "Statement": [
      {
        Effect: "Deny",
        Principal: "*",
        Action: "s3:*",
        Resource: "${aws_s3_bucket.prm-deductions-terraform-state.arn}/*",
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

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = {
     Name = "Terraform state of the prm-deductions-support-infra"
     CreatedBy = "prm-deductions-support-infra"
  }
}

resource "aws_s3_bucket_policy" "terraform-state-store" {
  bucket = aws_s3_bucket.prm-deductions-terraform-state-store.id
  policy = jsonencode({
    "Statement": [
      {
        Effect: "Deny",
        Principal: "*",
        Action: "s3:*",
        Resource: "${aws_s3_bucket.prm-deductions-terraform-state-store.arn}/*",
        Condition: {
          Bool: {
            "aws:SecureTransport": "false"
          }
        }
      }
    ]
  })
}

output "state_store" {
  value = "prm-deductions-${local.prefix}terraform-state-store"
}
