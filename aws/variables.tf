variable "region" {
  default = "ap-northeast-1"
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

variable "lambda-processor-name" {
  default = "lambda-processor"
}

variable "source-stream-name" {
  default = "source-stream"
}

variable "database" {
  default = "database"
}

variable "environment" {
  default = "dev"
}