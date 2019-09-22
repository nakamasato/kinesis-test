# Kinesis Example

## URL

https://aws.amazon.com/blogs/big-data/create-real-time-clickstream-sessions-and-run-analytics-with-amazon-kinesis-data-analytics-aws-glue-and-amazon-athena/

## Background

The link provides the CloudFormation stack, but it didn't work in Tokyo region. Created Terraform version to practice Kinesis.

## Description

1. [Lambda] `kinesis-data-generator` -> (input: None, output: [kinesis stream] `source-stream`)
2. [Kinesis analytics] `analytics` (Source data: `source-stream`, Real-time analytics: SQL, destination: `firehose-to-s3`)
3. [Kinesis firehose] `firehose-to-s3` (input: DESTINATION_SQL_STREAM, output: `s3://{bucket}/{processed}`)
4. [Kinesis firehose] `raw-raw-data-to-s3` (input: `source-stream`, output: `s3://{bucket}/{raw-data}`)
5. [Glue] (WIP)
6. [Athena] (WIP)
7. [Cloudwatch Dashboard] (WIP)

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

## Warning

Cloudwatch costs a lot!!

I ran the first version for a few days and it cost me nearly 70 USD! Please be careful. I decided not to write to cloudwatch in lambda-processor
