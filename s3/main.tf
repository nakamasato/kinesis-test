resource "aws_s3_bucket" "bucket" {
  bucket = var.s3-bucket
  acl    = "private"

  tags = {
    Environment = var.environment
  }
}
