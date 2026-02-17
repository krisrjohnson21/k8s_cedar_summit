# S3 bucket for Tofu state
resource "aws_s3_bucket" "cedar_summit_tofu" {
  bucket = "cedar-summit-tofu"
}

resource "aws_s3_bucket_versioning" "tofu_bucket_versioning" {
  bucket = aws_s3_bucket.cedar_summit_tofu.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Public access block for tofu state S3 bucket
resource "aws_s3_bucket_public_access_block" "cedar_summit_tofu" {
  bucket = aws_s3_bucket.cedar_summit_tofu.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# DynamoDB table for state lock
resource "aws_dynamodb_table" "tofu_state_lock" {
  name         = "tofu-statelock-cedar-summit"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
