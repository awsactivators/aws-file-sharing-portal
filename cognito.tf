#Cognito user pool
resource "aws_cognito_user_pool" "fsp_user_pool" {
  name                     = "fsp-user-pool"
  auto_verified_attributes = ["email"]

  tags = local.common_tags
}


# Google Identity Provider in Cognito
resource "aws_cognito_identity_provider" "fsp_google" {
  user_pool_id  = aws_cognito_user_pool.fsp_user_pool.id
  provider_name = "Google"
  provider_type = "Google"
  provider_details = {
    authorize_scopes              = "profile email openid"
    client_id                     = var.client_id
    client_secret                 = var.client_secret
  }

  attribute_mapping = {
    email    = "email"
    username = "sub"
  }

  lifecycle {
    ignore_changes = [provider_details]
  }
}


#Web client
resource "aws_cognito_user_pool_client" "fsp_user_pool_client" {
  name                                 = "fsp-app-client"
  user_pool_id                         = aws_cognito_user_pool.fsp_user_pool.id
  supported_identity_providers         = ["Google"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["profile", "openid", "email", "aws.cognito.signin.user.admin", "phone"]
  callback_urls                        = ["https://fsp-app.auth.us-east-1.amazoncognito.com", "http://localhost:3001/auth/", "http://localhost:3001/"]

}

resource "aws_cognito_resource_server" "fsp_scope" {
  name = "fsp-scope"
  identifier = "fsp-scope"
  user_pool_id = aws_cognito_user_pool.fsp_user_pool.id

  scope {
    scope_name = "custom_scope"
    scope_description = "custom scope"
  }
}

resource "aws_cognito_user_pool_domain" "fsp_user_pool_domain" {
  domain          = "fsp-app.pendulum.global"
  certificate_arn = "arn:aws:acm:us-east-1:393000674573:certificate/86377542-f363-4ee4-a76e-81b6a46c1499"
  user_pool_id    = aws_cognito_user_pool.fsp_user_pool.id
}