resource "aws_kinesis_stream" "kinesis-source-stream" {
  name             = var.source-stream-name
  shard_count      = 2
  retention_period = 48

  shard_level_metrics = [
    "IncomingBytes",
    "OutgoingBytes",
  ]

  tags = {
    Environment = var.environment
  }
}

resource "aws_kinesis_analytics_application" "kinesis-analytics" {
  name = "kinesis-analytics"

  inputs {
    name_prefix = "SOURCE_SQL_STREAM"

    kinesis_stream { # or kinesis_firehose
      resource_arn = aws_kinesis_stream.kinesis-source-stream.arn
      role_arn     = aws_iam_role.kinesis-analytics-role.arn
    }

    parallelism {
      count = 1
    }

    schema {
      # https://docs.aws.amazon.com/kinesisanalytics/latest/sqlref/sql-reference-data-types.html
      record_columns {
        mapping  = "$.user_id"
        name     = "user_id"
        sql_type = "INTEGER"
      }

      record_columns {
        mapping  = "$.device_id"
        name     = "device_id"
        sql_type = "VARCHAR(8)"
      }

      record_columns {
        mapping  = "$.client_event"
        name     = "client_event"
        sql_type = "VARCHAR(16)"
      }

      record_columns {
        mapping  = "$.client_timestamp"
        name     = "client_timestamp"
        sql_type = "TIMESTAMP"
      }

      record_encoding = "UTF-8"

      record_format {
        mapping_parameters {
          json {
            record_row_path = "$"
          }
        }
      }
    }
  }

  outputs {
    name = "DESTINATION_SQL_STREAM"

    schema {
      record_format_type = "JSON"
    }

    lambda {
      resource_arn = aws_lambda_function.lambda-processor.arn
      role_arn     = aws_iam_role.kinesis-analytics-role.arn
    }
  }

  code = file("./kinesis-analysis/analytics.sql")
}

resource "aws_iam_role" "kinesis-analytics-role" {
  name = "kinesis-analytics-role"
  assume_role_policy = data.aws_iam_policy_document.kinesis-analytics-assume-role-policy-document.json
  description = "Regulates the permissions for kinesis-analytics application stream"
  tags = {
    Environment = var.environment
  }
}

data "aws_iam_policy_document" "kinesis-analytics-assume-role-policy-document" {
  statement {
    effect = "Allow"

    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["kinesisanalytics.amazonaws.com"]
      type = "Service"
    }
  }
}

resource "aws_iam_policy" "kinesis-analysis-policy" {
  name = "kinesis-analytics-policy"
  description = "kinesis analytics policy"
  policy = data.aws_iam_policy_document.kinesis-analytics-policy-document.json
}

data "aws_iam_policy_document" "kinesis-analytics-policy-document" {
  statement {
    sid = "ReadInputKinesis"

    effect = "Allow"

    actions = [
      "kinesis:GetShardIterator",
      "kinesis:GetRecords",
      "kinesis:DescribeStream"
    ]

    resources = [
      aws_kinesis_stream.kinesis-source-stream.arn
    ]
  }

  statement {
    sid = "WriteOutputFirehose"

    effect = "Allow"

    actions = [
      "firehose:DescribeDeliveryStream",
      "firehose:PutRecord",
      "firehose:PutRecordBatch"
    ]

    resources = [
      aws_kinesis_firehose_delivery_stream.firehose-to-s3.arn,
      "arn:aws:kinesis:${var.region}::stream/kinesis-analytics-placeholder-stream-destination"
    ]
  }

  statement {
    sid = "LambdaWrite"

    effect = "Allow"

    actions = [
      "lambda:*"
    ]

    resources = [
      aws_lambda_function.lambda-processor.arn
    ]
  }

  statement {
    sid = "WriteOutputKinesis"

    effect = "Allow"

    actions = [
      "kinesis:DescribeStream",
      "kinesis:PutRecord",
      "kinesis:PutRecords"
    ]

    resources = [
      "arn:aws:kinesis:${var.region}::stream/kinesis-analytics-placeholder-stream-destination"
    ]
  }

}

resource "aws_iam_role_policy_attachment" "analytics-policy-attach" {
  role = aws_iam_role.kinesis-analytics-role.name
  policy_arn = aws_iam_policy.kinesis-analysis-policy.arn
}
