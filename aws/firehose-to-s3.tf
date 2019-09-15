resource "aws_kinesis_firehose_delivery_stream" "firehose-to-s3" {
  name        = "firehose-to-s3"
  destination = "s3"

  s3_configuration {
    role_arn           = aws_iam_role.firehose-to-s3-role.arn
    bucket_arn         = aws_s3_bucket.bucket.arn
    prefix             = "${var.s3-prefix-processed}/"
    compression_format = "GZIP"
    buffer_size        = 10
    buffer_interval    = 60
  }
}

resource "aws_iam_role" "firehose-to-s3-role" {
  name = "firehose-to-s3-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "firehose.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

data "aws_iam_policy_document" "firehose-to-s3-policy-document" {
  statement {
    effect = "Allow"

    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:PutObject"
    ]

    resources = [
      aws_s3_bucket.bucket.arn,
      "${aws_s3_bucket.bucket.arn}/*"
    ]

  }
  statement {
    effect = "Allow"

    actions = [
      "logs:PutLogEvents"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "firehose-to-s3-policy" {
  name = "firehose-to-s3-policy"
  description = "firehose to s3 policy"
  policy = data.aws_iam_policy_document.firehose-to-s3-policy-document.json
}

resource "aws_iam_role_policy_attachment" "firehose-to-s3-attach" {
  role = aws_iam_role.firehose-to-s3-role.name
  policy_arn = aws_iam_policy.firehose-to-s3-policy.arn
}
