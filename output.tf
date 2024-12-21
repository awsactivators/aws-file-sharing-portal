#API URL
output "api_gateway_invoke_url" {
  value = aws_api_gateway_deployment.fsp_api_deployment.invoke_url
}

# cognito userpool
output "userpool_id" {
  value = aws_cognito_user_pool.fsp_user_pool.id
}

#cognito client
output "client_id" {
  value = aws_cognito_user_pool_client.fsp_user_pool_client.id
}