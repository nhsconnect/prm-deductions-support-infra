# S3 bucket to hold terraform states
resource "aws_s3_bucket" "prm-deductions-terraform-state" {
  bucket = "prm-deductions-terraform-state"
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
  }
}
