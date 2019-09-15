data "archive_file" "lambda-data-generator-zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda-data-generator-code"
  output_path = "${path.module}/lambda-data-generator-code/function.zip"
}

resource "aws_lambda_function" "kinesis-data-generator" {
  function_name = "kinesis-data-generator"

  description = "[dev] generate fake clickstream data"

  filename = "${path.module}/lambda-data-generator-code/function.zip"

  handler = "lambda_function.lambda_handler"
  runtime = "python3.7"
  timeout = 60

  role             = aws_iam_role.kinesis-data-generator-role.arn
  source_code_hash = data.archive_file.lambda-data-generator-zip.output_base64sha256

  environment {
    variables = {
      SOURCE_STREAM_NAME = var.source-stream-name
    }
  }

  tags = {
    "Environment" = var.environment
  }

}

resource "aws_iam_role" "kinesis-data-generator-role" {
  name = "kinesis-data-generator-role"

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

data "aws_iam_policy_document" "kinesis-data-generator-policy-document" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
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
      "kinesis:GetRecords",
      "kinesis:PutRecords",
      "kinesis:PutRecord"
    ]

    resources = [aws_kinesis_stream.kinesis-source-stream.arn]
  }
}


resource "aws_iam_policy" "kinesis-data-generator-policy" {
  name = "kinesis-data-generator-policy"
  description = "A test lambda policy"
  policy = data.aws_iam_policy_document.kinesis-data-generator-policy-document.json
}

resource "aws_iam_role_policy_attachment" "kinesis-data-generator-attach" {
  role = aws_iam_role.kinesis-data-generator-role.name
  policy_arn = aws_iam_policy.kinesis-data-generator-policy.arn
}


## event scheduler

resource "aws_cloudwatch_event_rule" "every_min" {
  name = "every_min"
  description = "Fires every minute"
  schedule_expression = "cron(* * * * ? *)"
}

resource "aws_cloudwatch_event_target" "every-min-kinesis-data-generator" {
  rule = "${aws_cloudwatch_event_rule.every_min.name}"
  target_id = "kinesis-data-generator"
  arn = "${aws_lambda_function.kinesis-data-generator.arn}"
}

resource "aws_lambda_permission" "allow-cloudwatch-to-call-kinesis-data-generator" {
  statement_id = "AllowExecutionFromCloudWatch"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.kinesis-data-generator.function_name
  principal = "events.amazonaws.com"
  source_arn = aws_cloudwatch_event_rule.every_min.arn
}