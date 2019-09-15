resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "DataAnalyticsStreamingDashboard"

  dashboard_body = <<EOF
{
   "widgets": [
       {
          "type":"metric",
          "x":0,
          "y":0,
          "width":24,
          "height":3,
          "properties":{
             "metrics":[
                [
                   "AWS/KinesisAnalytics",
                   "Records",
                   "Id",
                   "1.1",
                   "Application",
                   "${aws_kinesis_analytics_application.kinesis-analytics.name}",
                   "Flow",
                   "Output"
                ],
                [ ".", "Bytes", ".", ".", ".", ".", ".", "." ],
                [ ".", "Records", ".", ".", ".", ".", ".", "Inputs" ],
                [ ".", "Bytes", ".", ".", ".", ".", ".", "." ]
             ],
             "period":300,
             "stat":"Sum",
             "region":"${var.region}",
             "view":"SingleValue"
          }
       }
   ]
}

EOF
}