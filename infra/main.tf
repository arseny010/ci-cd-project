resource "random_id" "suffix" {
  byte_length = 2
}

resource "aws_s3_bucket" "demo" {
  bucket = "arseny-ci-cd-demo-${random_id.suffix.hex}"
  tags = {
    Project     = "ci-cd-project"
    Environment = "dev"
    Owner       = "arseny avseenko"
  }
}

output "bucket_name" {
  value = aws_s3_bucket.demo.bucket
}