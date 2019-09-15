# Kinesis Example

## URL

https://aws.amazon.com/blogs/big-data/create-real-time-clickstream-sessions-and-run-analytics-with-amazon-kinesis-data-analytics-aws-glue-and-amazon-athena/

## Background

The link provides the CloudFormation stack, but it didn't work in Tokyo region. Created Terraform version to practice Kinesis.

## Description

1. [Lambda] `kinesis-data-generator` -> (input: None, output: [kinesis stream] `source-stream`)
2. [Kinesis analytics] `analytics` (Source data: `source-stream`, Real-time analytics: SQL, destination: `kinesis-processor`)
4. [Lambda] `kinesis-processor` (input: `DESTINATION_SQL_STREAM` from Real-time analytics, output: `firehose-to-s3`)
5. [Kinesis firehose] `firehose-to-s3` (input: processed data from `kinesis-processor`, output: `s3://{bucket}/{processed}`)
6. [Kinesis firehose] `raw-raw-data-to-s3` (input: `source-stream`, output: `s3://{bucket}/{raw-data}`)
7. [Glue] (WIP)
8. [Athena] (WIP)
9. [Cloudwatch Dashboard] (WIP)

# install dependencies

## terraform

```
brew install tfenv
tfenv install <version>
tfenv use <version>
```

## Setup

```
terraform init
terraform plan
terraform apply
```



