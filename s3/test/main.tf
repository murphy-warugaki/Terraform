variable "name" {
  bucket = "string"
}

resource "aws_s3_bucket" "this" {
  bucket = var.bucket

  lifecycle_rule {
    enabled = true

    expiration {
      days = "180"
    }
  }
}

output "bucket_id" {
  value = aws_s3_bucket.this.id
}
