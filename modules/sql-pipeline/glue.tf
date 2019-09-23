resource "aws_glue_catalog_database" "database" {
  name = "${var.pipeline-name}-${var.database}"
}

resource "aws_glue_catalog_table" "raw-table" {
  name          = var.s3-prefix-raw-data
  database_name = aws_glue_catalog_database.database.name
}

resource "aws_glue_catalog_table" "processed-table" {
  name          = var.s3-prefix-processed
  database_name = aws_glue_catalog_database.database.name
}

resource "aws_glue_crawler" "crawler" {
  database_name = aws_glue_catalog_database.database.name
  name          = "${var.pipeline-name}-crawler"
  role          = aws_iam_role.glue-role.arn

  s3_target {
    path = "s3://${data.aws_s3_bucket.bucket.bucket}"
  }

  schema_change_policy {
    update_behavior = "UPDATE_IN_DATABASE"
    delete_behavior = "DELETE_FROM_DATABASE"
  }

  schedule = "cron(0 * * * ? *)"
}

resource "aws_iam_role" "glue-role" {
  name = "${var.pipeline-name}-glue-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "glue.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

data "aws_iam_policy_document" "glue-policy-document" {
  statement {
    effect = "Allow"
    actions = ["*"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "glue-policy" {
  name = "${var.pipeline-name}-glue-policy"
  description = "glue"
  policy = data.aws_iam_policy_document.glue-policy-document.json
}

resource "aws_iam_role_policy_attachment" "glue-policy-attach" {
  role = aws_iam_role.glue-role.name
  policy_arn = aws_iam_policy.glue-policy.arn
}