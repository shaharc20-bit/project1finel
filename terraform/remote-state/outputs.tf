output "state_bucket" {
  value = aws_s3_bucket.state.bucket
}

output "lock_table" {
  value = aws_dynamodb_table.locks.name
}

output "next_step" {
  value = "cd .. && terraform init -backend-config=backend.hcl && terraform apply"
}
