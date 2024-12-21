# Create Lambda Upload Function
resource "aws_lambda_function" "fsp_lambda" {
  function_name = "fsp-upload-lambda-function"
  handler       = "index.lambda_handler"
  runtime       = "python3.11"
  filename      = local.lambda_function_zip_path 
  role          = aws_iam_role.fsp_lambda_iam_role.arn
  memory_size   = 128
  timeout       = 60
  source_code_hash = data.archive_file.fsp_source.output_base64sha256
  depends_on    = [aws_iam_role.fsp_lambda_iam_role, aws_s3_bucket.fsp_upload_bucket]

  environment {
    variables = {
      UPLOAD_BUCKET_NAME = "pendulum-uploads"
      FORECAST_LAMBDA_NAME = "fsp-forcasting-lambda-function"
    }
  }
}


#Create Lambda Forcasting Function
resource "aws_lambda_function" "fsp_forcasting_handler" {
  function_name = "fsp-forcasting-lambda-function"
  handler       = "lambda.lambda_handler"
  runtime       = "python3.11"
  filename     = local.lambda_function_forecaasting_zip_path 
  role          = aws_iam_role.fsp_lambda_iam_role.arn
  memory_size   = 128
  timeout       = 60
  depends_on    = [aws_iam_role.fsp_lambda_iam_role]
}
