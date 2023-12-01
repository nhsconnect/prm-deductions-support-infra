# DynamoDB table to keep the state locks.
resource "aws_dynamodb_table" "prm-deductions-terraform-table" {
  name                        = "prm-deductions-${local.prefix}terraform-table"
  billing_mode                = "PROVISIONED"
  read_capacity               = 2
  write_capacity              = 2
  hash_key                    = "LockID"
  deletion_protection_enabled = true

  point_in_time_recovery {
    enabled = true
  }

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name      = "Terraform Lock Table"
    CreatedBy = "prm-deductions-support-infra"
  }
}
