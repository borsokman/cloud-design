resource "aws_cognito_user_pool" "pool" {
  name = "microservices-users"

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
  }
}

resource "aws_cognito_user_pool_domain" "main" {
  domain       = "microservices-borsok" # Must be globally unique, change if taken
  user_pool_id = aws_cognito_user_pool.pool.id
}

resource "aws_cognito_user_pool_client" "client" {
  name                                 = "alb-client"
  user_pool_id                         = aws_cognito_user_pool.pool.id
  generate_secret                      = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["openid", "email", "profile"]
  allowed_oauth_flows_user_pool_client = true
  supported_identity_providers         = ["COGNITO"]
  
  # The callback URL tells Cognito where to send the user after they log in.
  callback_urls                        = ["https://${aws_lb.main_alb.dns_name}/oauth2/idpresponse"]
}