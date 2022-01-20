# Input

- pipeline-name (used for prefix for resources to be created)
- source stream name
- s3 bucket name (should be prepared in advance) to be used for storing output data
- output dir of s3 (rawdata, processed)
- database name
- crawler name
- environment (e.g. dev, prod)
- analytics.sql (core logic of processing)

# Resources to be created

- Kinesis Stream
- Kinesis Analytics
- Kinesis Firehose x 2
- Glue Catalog Database
- Glue Catalog Table x 2
- Glue Crawler
- IAM Policy x 4
- IAM Role x 8

# Issues

- Cannot configure schema for input data
- Cannot use root main.tf because of the relative input of analytics.sql
