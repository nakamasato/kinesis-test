# data "archive_file" "lambda-create-kinesis-analytics-zip" {
#   type        = "zip"
#   source_dir  = "${path.module}/lambda-create-kinesis-analytics-code"
#   output_path = "${path.module}/lambda-create-kinesis-analytics-code/function.zip"
# }

# resource "aws_lambda_function" "kinesis-create-kinesis-analytics" {
#   function_name = "kinesis-create-kinesis-analytics"

#   description = "[dev] This function configures and launches a Kinesis Analytics Application"

#   filename = "${path.module}/lambda-create-kinesis-analytics-code/function.zip" # .gitignore

#   handler = "lambda_function.lambda_handler"
#   runtime = "python3.7"
#   timeout = 30

#   role             = aws_iam_role.kinesis-create-kinesis-analytics-role.arn
#   source_code_hash = data.archive_file.lambda-create-kinesis-analytics-zip.output_base64sha256

#   environment {
#     variables = {
#       SOURCE_STREAM_NAME = var.source-stream-name
#     }
#   }

#   tags = {
#     "Environment" = var.environment
#   }

# }

# resource "aws_iam_role" "kinesis-create-kinesis-analytics-role" {
#   name = "kinesis-create-kinesis-analytics-role"

#   assume_role_policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Action": "sts:AssumeRole",
#       "Principal": {
#         "Service": "lambda.amazonaws.com"
#       },
#       "Effect": "Allow",
#       "Sid": ""
#     }
#   ]
# }
# EOF
# }

# data "aws_iam_policy_document" "kinesis-create-kinesis-analytics-policy-document" {
#   statement {
#     effect = "Allow"

#     actions = [
#       "logs:CreateLogGroup",
#       "logs:CreateLogStream",
#       "logs:PutLogEvents",
#     ]

#     resources = [
#       "*"
#     ]

#   }
#   statement {
#     effect = "Allow"

#     actions = [
# "kinesisanalytics:CreateApplication",
#                                         "kinesisanalytics:DeleteApplication",
#                                         "kinesisanalytics:DescribeApplication"
#     ]

#     resources = ["arn:aws:kinesisanalytics:${var.region}::applications/*"]
#   }

#   statement {
#     effect = "Allow"

#     actions = [
# "kinesisanalytics:ListApplications",
# "cloudwatch:GetMetricStatistics"
#     ]

#     resources = ["*"]
#   }

#   statement {
#     effect = "Allow"

#     actions = [
#  "s3:GetObject"
#     ]

#     resources = [
#     "arn:aws:s3:::aws-bigdata-blog/artifacts/realtime-clickstream-sessions-analytics-kinesis-glue-athena/streaming-analytics-stagger-config-minutes.yaml",
#     "arn:aws:s3:::aws-bigdata-blog/artifacts/realtime-clickstream-sessions-analytics-kinesis-glue-athena/streaming-analytics-stagger-config-minutes.yaml"
#     ]
#   }

#   statement {
#     effect = "Allow"

#     actions = [
# "iam:PassRole"
#     ]

#     resources = [aws_iam_role.kinesis-analytics-role.arn]
#   }
# }


# resource "aws_iam_policy" "kinesis-create-kinesis-analytics-policy" {
#   name = "kinesis-create-kinesis-analytics-policy"
#   description = "A test lambda policy"
#   policy = data.aws_iam_policy_document.kinesis-create-kinesis-analytics-policy-document.json
# }

# resource "aws_iam_role_policy_attachment" "kinesis-create-kinesis-analytics-attach" {
#   role = aws_iam_role.kinesis-create-kinesis-analytics-role.name
#   policy_arn = aws_iam_policy.kinesis-create-kinesis-analytics-policy.arn
# }

