#Creating API Gateway for the REST API

resource "aws_api_gateway_rest_api" "fsp_api" {
  name        = "FSP-REST-API"
  description = "REST API for File Sharing Portal"
}

resource "aws_api_gateway_resource" "fsp_api_resource" {
  parent_id   = aws_api_gateway_rest_api.fsp_api.root_resource_id
  path_part   = "upload"
  rest_api_id = aws_api_gateway_rest_api.fsp_api.id

  depends_on = [ aws_api_gateway_rest_api.fsp_api ]
}

resource "aws_api_gateway_method" "fsp_api_post_method" {
  authorization = "COGNITO_USER_POOLS"
  http_method   = "POST"
  resource_id   = aws_api_gateway_resource.fsp_api_resource.id
  rest_api_id   = aws_api_gateway_rest_api.fsp_api.id
  authorizer_id = aws_api_gateway_authorizer.fsp_api_cognito_authorizer.id

  depends_on = [ aws_api_gateway_rest_api.fsp_api ]
}

resource "aws_api_gateway_integration" "fsp_api_post_integration" {
  http_method = aws_api_gateway_method.fsp_api_post_method.http_method
  resource_id = aws_api_gateway_resource.fsp_api_resource.id
  rest_api_id = aws_api_gateway_rest_api.fsp_api.id
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.fsp_lambda.invoke_arn
}


# Method Response and Enabling CORS

resource "aws_api_gateway_method_response" "fsp_api_post_method_response" {
  rest_api_id = aws_api_gateway_rest_api.fsp_api.id
  resource_id = aws_api_gateway_resource.fsp_api_resource.id
  http_method = aws_api_gateway_method.fsp_api_post_method.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true,
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true
  }

  depends_on = [ aws_api_gateway_method.fsp_api_post_method ]

}

resource "aws_api_gateway_deployment" "fsp_api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.fsp_api.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.fsp_api_resource.id,
      aws_api_gateway_method.fsp_api_post_method.id,
      aws_api_gateway_integration.fsp_api_post_integration.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on  = [aws_api_gateway_integration.fsp_api_post_integration]
}

resource "aws_api_gateway_stage" "fsp_api_stage" {
  deployment_id = aws_api_gateway_deployment.fsp_api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.fsp_api.id
  stage_name    = "prod"
}

# Permission for API Gateway to invoke lambda function
resource "aws_lambda_permission" "fsp_apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.fsp_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn = "arn:aws:execute-api:${var.aws_region}:${var.aws_account_id}:${aws_api_gateway_rest_api.fsp_api.id}/*/${aws_api_gateway_method.fsp_api_post_method.http_method}${aws_api_gateway_resource.fsp_api_resource.path}"
}


#Create Cognito User Pools authorizer
resource "aws_api_gateway_authorizer" "fsp_api_cognito_authorizer" {
  name                   = "CognitoAuthorizer"
  rest_api_id            = aws_api_gateway_rest_api.fsp_api.id
  type                   = "COGNITO_USER_POOLS"
  identity_source        = "method.request.header.Authorization"
  provider_arns          = ["arn:aws:cognito-idp:${var.aws_region}:${var.aws_account_id}:userpool/${aws_cognito_user_pool.fsp_user_pool.id}"]
  authorizer_credentials = aws_iam_role.fsp_invocation_role.arn
  authorizer_uri         = aws_lambda_function.fsp_lambda.invoke_arn

}

resource "aws_api_gateway_api_key" "fsp_api_key" {
  name  = "fsp-api-key"
}

resource "aws_api_gateway_usage_plan" "fsp_api_usage_plan" {
  name  = "fsp-api-usage-plan"

  api_stages {
    api_id = aws_api_gateway_rest_api.fsp_api.id
    stage  = aws_api_gateway_stage.fsp_api_stage.stage_name
  }
}

resource "aws_api_gateway_usage_plan_key" "fsp_api_usage_plan_key" {
  key_id        = aws_api_gateway_api_key.fsp_api_key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.fsp_api_usage_plan.id
}