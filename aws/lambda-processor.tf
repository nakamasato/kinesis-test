data "archive_file" "lambda-processor-zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda-processor-code"
  output_path = "${path.module}/lambda-processor-code/function.zip"
}

resource "aws_lambda_function" "lambda-processor" {
  function_name = "kinesis-processor"

  description = "[dev] destination of Kinesis Analytics"

  filename = "${path.module}/lambda-processor-code/function.zip"

  handler = "lambda_function.lambda_handler"
  runtime = "python3.7"
  timeout = 180

  role             = aws_iam_role.lambda-processor-role.arn
  source_code_hash = data.archive_file.lambda-processor-zip.output_base64sha256

  environment {
    variables = {
      DELIVERY_STREAM_NAME = aws_kinesis_firehose_delivery_stream.firehose-to-s3.name
    }
  }

  tags = {
    Environment = var.environment
  }

}

resource "aws_iam_role" "lambda-processor-role" {
  name = "kinesis-processor-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

data "aws_iam_policy_document" "lambda-processor-policy-document" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "cloudwatch:PutMetricData"
    ]

    resources = [
      "*"
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
    actions = ["firehose:*"]
    resources = [
      aws_kinesis_firehose_delivery_stream.firehose-to-s3.arn
      # aws_kinesis_firehose_delivery_stream.raw-data-to-s3.arn
    ]
  }
}

resource "aws_iam_policy" "lambda-processor-policy" {
  name = "kinesis-processor-policy"
  description = "lambda kinesis processor"
  policy = data.aws_iam_policy_document.lambda-processor-policy-document.json
}

resource "aws_iam_role_policy_attachment" "lambda-processor-attach" {
  role = aws_iam_role.lambda-processor-role.name
  policy_arn = aws_iam_policy.lambda-processor-policy.arn
}


resource "aws_lambda_event_source_mapping" "lambda-processor-event-source-mapping" {
  event_source_arn = aws_kinesis_stream.kinesis-source-stream.arn
  function_name = aws_lambda_function.lambda-processor.arn
  starting_position = "LATEST"
}