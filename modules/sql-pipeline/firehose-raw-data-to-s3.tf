resource "aws_kinesis_firehose_delivery_stream" "raw-data-to-s3" {
  name        = "${var.pipeline-name}-firehose-raw-data-to-s3"
  destination = "s3"

  kinesis_source_configuration {
    kinesis_stream_arn = aws_kinesis_stream.kinesis-source-stream.arn
    role_arn           = aws_iam_role.firehose-raw-data-to-s3-role.arn
  }

  s3_configuration {
    role_arn           = aws_iam_role.firehose-raw-data-to-s3-role.arn
    bucket_arn         = data.aws_s3_bucket.bucket.arn
    prefix             = "${var.pipeline-name}/${var.s3-prefix-raw-data}/"
    compression_format = "GZIP"
    buffer_size        = 10
    buffer_interval    = 60
  }

  tags = {
    Environment = var.environment
  }
}

resource "aws_iam_role" "firehose-raw-data-to-s3-role" {
  name = "${var.pipeline-name}-firehose-raw-data-to-s3-role"

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

data "aws_iam_policy_document" "raw-data-to-s3-policy-document" {
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
      data.aws_s3_bucket.bucket.arn,
      "${data.aws_s3_bucket.bucket.arn}/${var.pipeline-name}/${var.s3-prefix-raw-data}/*"
    ]

  }
  statement {
    effect = "Allow"

    actions = [
      "kinesis:DescribeStream",
      "kinesis:GetShardIterator",
      "kinesis:GetRecords"
    ]

    resources = [aws_kinesis_stream.kinesis-source-stream.arn]
  }
  statement {
    effect = "Allow"
    actions = ["logs:PutLogEvents"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "raw-data-to-s3-policy" {
  name = "${var.pipeline-name}-raw-data-to-s3-policy"
  description = "raw data to s3"
  policy = data.aws_iam_policy_document.raw-data-to-s3-policy-document.json
}

resource "aws_iam_role_policy_attachment" "raw-data-to-s3-policy-attach" {
  role = aws_iam_role.firehose-raw-data-to-s3-role.name
  policy_arn = aws_iam_policy.raw-data-to-s3-policy.arn
}
