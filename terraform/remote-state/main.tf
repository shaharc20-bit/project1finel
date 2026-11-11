resource "aws_s3_bucket" "state" {
  bucket_prefix = "${var.owner}-${var.project}-"
  force_destroy = var.force_destroy
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket                  = aws_s3_bucket.state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "locks" {
  name         = "${var.project}-tf-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

resource "local_file" "backend_config" {
  filename        = "${path.module}/../backend.hcl"
  file_permission = "0644"
  content         = <<-EOT
    bucket         = "${aws_s3_bucket.state.bucket}"
    key            = "${var.state_key}"
    region         = "${var.region}"
    dynamodb_table = "${aws_dynamodb_table.locks.name}"
    encrypt        = true
  EOT
}

resource "local_file" "bucket_vars" {
  filename        = "${path.module}/../remote-state.auto.tfvars"
  file_permission = "0644"
  content         = <<-EOT
    backup_bucket = "${aws_s3_bucket.state.bucket}"
  EOT
}
