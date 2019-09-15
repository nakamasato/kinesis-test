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


  code = <<EOF
-- CREATE a Stream to receive the query aggregation result
CREATE OR REPLACE STREAM "DESTINATION_SQL_STREAM"
(
  session_id VARCHAR(60),
  user_id INTEGER,
  device_id VARCHAR(10),
  timeagg timestamp,
  events INTEGER,
  beginnavigation VARCHAR(32),
  endnavigation VARCHAR(32),
  beginsession VARCHAR(25),
  endsession VARCHAR(25),
  duration_sec INTEGER
);

-- Create the PUMP
CREATE OR REPLACE PUMP "WINDOW_PUMP_SEC" AS INSERT INTO "DESTINATION_SQL_STREAM"
-- Insert as Select
    SELECT  STREAM
-- Make the Session ID using user_ID+device_ID and Timestamp
    UPPER(cast("user_id" as VARCHAR(3))|| '_' ||SUBSTRING("device_id",1,3)
    ||cast( UNIX_TIMESTAMP(STEP("client_timestamp" by interval '30' second))/1000 as VARCHAR(20))) as session_id,
    "user_id" , "device_id",
-- create a common rounded STEP timestamp for this session
    STEP("client_timestamp" by interval '30' second),
-- Count the number of client events , clicks on this session
    COUNT("client_event") events,
-- What was the first navigation action
    first_value("client_event") as beginnavigation,
-- what was the last navigation action
    last_value("client_event") as endnavigation,
-- begining minute and second
    SUBSTRING(cast(min("client_timestamp") AS VARCHAR(25)),15,19) as beginsession,
-- ending minute and second
    SUBSTRING(cast(max("client_timestamp") AS VARCHAR(25)),15,19) as endsession,
-- session duration
    TSDIFF(max("client_timestamp"),min("client_timestamp"))/1000 as duration_sec
-- from the source stream
    FROM "SOURCE_SQL_STREAM_001"
-- using stagger window , with STEP to Seconds, for Seconds intervals
    WINDOWED BY STAGGER (
                PARTITION BY "user_id", "device_id", STEP("client_timestamp" by interval '30' second)
                RANGE INTERVAL '30' SECOND );
EOF
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
