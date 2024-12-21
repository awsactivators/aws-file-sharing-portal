# CloudWatch
resource "aws_cloudwatch_dashboard" "example_dashboard" {
  dashboard_name = "FileUploadMetricsDashboard"

  dashboard_body = jsonencode({
  "widgets": [
    {
      "type": "metric",
      "x": 0,
      "y": 0,
      "width": 12,
      "height": 6,
      "properties": {
        "metrics": [
          ["FSP/FileUploads", "UploadDuration", "FunctionName", "${aws_lambda_function.fsp_lambda.function_name}", { "stat": "Average", "period": 300 }],
          [".", "SuccessfulUploads", "FunctionName", "${aws_lambda_function.fsp_lambda.function_name}", { "stat": "Sum", "period": 86400 }],
          [".", "UploadDuration", "FunctionName", "${aws_lambda_function.fsp_forcasting_handler.function_name}", { "stat": "Average", "period": 300 }],
          [".", "SuccessfulUploads", "FunctionName", "${aws_lambda_function.fsp_forcasting_handler.function_name}", { "stat": "Sum", "period": 86400 }]
        ],
        "view": "timeSeries",
        "stacked": false,
        "title": "FSP Upload Metrics",
        "region": "us-east-1",
        "period": 300
      }
    },
    {
      "type": "log",
      "x": 0,
      "y": 7,
      "width": 12,
      "height": 6,
      "properties": {
        "query": "fields @timestamp, @message | filter @message like /Error/ and (@logStream like /${aws_lambda_function.fsp_lambda.function_name}/ or @logStream like /${aws_lambda_function.fsp_forcasting_handler.function_name}/) | stats count(*) as ErrorCount by bin(1d)",
        "region": "us-east-1",
        "title": "FSP Error Logs",
        "view": "table"
      }
    }
  ]
})
}



# SNS

resource "aws_cloudwatch_metric_alarm" "fsp_upload_duration_alarm" {
  alarm_name          = "fsp_high_upload_duration"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "UploadDuration"
  namespace           = "FSP/FileUploads"
  period              = "60"
  statistic           = "Average"
  threshold           = "10" 
  alarm_description   = "Alarm when upload duration exceeds 80 seconds on average over a 5-minute period."
  actions_enabled     = true

  alarm_actions = [aws_sns_topic.fsp_alarm_topic.arn]

  dimensions = {
    FunctionName = "fsp-upload-lambda-function"
  }


  # Set the alarm to "OK" state if the metric falls back within the threshold
  ok_actions = [aws_sns_topic.fsp_alarm_topic.arn]

}


resource "aws_sns_topic" "fsp_alarm_topic" {
  name = "fsp-upload-duration-alarm-topic"
}