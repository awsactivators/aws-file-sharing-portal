# AWS IAM Role for Lambda to access S3 and CloudWatch Logs
resource "aws_iam_role" "fsp_lambda_iam_role" {
  name = "fsp_lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      },
    }]
  })
}

# Policy to allow Lambda function to access S3, Api gateway, Cognito, and CloudWatch Logs
resource "aws_iam_policy" "fsp_lambda_policy" {
  name   = "fsp_lambda_policy"
  policy = data.aws_iam_policy_document.fsp_lambda_policy_doc.json
}

# Policy document
data "aws_iam_policy_document" "fsp_lambda_policy_doc" {
  statement {
    actions   = ["s3:PutObject", "s3:GetObject", "s3:DeleteObject"]
    resources = [
      "${aws_s3_bucket.fsp_upload_bucket.arn}/*",
      "${aws_s3_bucket.fsp_lambda_function_bucket.arn}/*"
    ]
  }
  statement {
    actions   = ["s3:ListBucket"]
    resources = [
      aws_s3_bucket.fsp_upload_bucket.arn,
      aws_s3_bucket.fsp_lambda_function_bucket.arn
    ]
  }
  statement {
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents", "logs:DescribeLogStreams", "cognito-idp:*", "apigateway:*"]
    resources = ["*"]
  }
}

# Attach policy to IAM role
resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.fsp_lambda_iam_role.name
  policy_arn = aws_iam_policy.fsp_lambda_policy.arn
}




# IAM Role for API Gateway execution
resource "aws_iam_role" "fsp_api_gateway_execution_role" {
  name = "ApiGatewayExecutionRole"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "apigateway.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "fsp_apigateway_policy" {
  name   = "fsp_apigateway_policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "apigateway:*"
        ],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}

# Attach policies to the IAM role (adjust policies based on your needs)
resource "aws_iam_role_policy_attachment" "fsp_api_gateway_execution_role_policy" {
  policy_arn = aws_iam_policy.fsp_apigateway_policy.arn
  role       = aws_iam_role.fsp_api_gateway_execution_role.name
}


data "aws_iam_policy_document" "fsp_invocation_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "fsp_invocation_role" {
  name               = "fsp_api_gateway_auth_invocation"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.fsp_invocation_assume_role.json
}

data "aws_iam_policy_document" "fsp_invocation_policy" {
  statement {
    effect    = "Allow"
    actions   = ["lambda:InvokeFunction"]
    resources = [aws_lambda_function.fsp_lambda.arn]
  }
}

resource "aws_iam_role_policy" "fsp_invocation_policy" {
  name   = "fsp_invocation_policy"
  role   = aws_iam_role.fsp_invocation_role.id
  policy = data.aws_iam_policy_document.fsp_invocation_policy.json
}