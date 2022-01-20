variable "region" {
  default = "ap-northeast-1"
}

variable "pipeline-name" {
  default = "pipeline-dev"
}

variable "s3-bucket" {
  default = "naka-kinesis-test"
}

variable "s3-prefix-raw-data" {
  default = "rawdata"
}

variable "s3-prefix-processed" {
  default = "processed"
}

variable "source-stream-name" {
  default = "source-stream"
}

variable "database" {
  default = "database"
}

variable "glue-crawler-name" {
  default = "test-crawler"
}

variable "environment" {
  default = "dev"
}
