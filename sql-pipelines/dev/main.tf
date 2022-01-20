module "sql-pipeline-dev" {
  source = "../../modules/sql-pipeline/"

  s3-bucket           = "naka-kinesis-test"
  pipeline-name       = "kinesis-dev"
  s3-prefix-raw-data  = "rawdata"
  s3-prefix-processed = "processed"
  source-stream-name  = "source-stream"
  database            = "database"
  glue-crawler-name   = "test-crawler"
  environment         = "dev"
}
