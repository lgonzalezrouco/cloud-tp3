# Lambda zip file should be built manually using build_lambda.sh or build_lambda.bat

data "aws_secretsmanager_secret_version" "client_secret" {
  count     = var.client_secret_arn != "" ? 1 : 0
  secret_id = var.client_secret_arn
}

resource "aws_lambda_function" "cognito_callback" {
  function_name    = "${var.app_name}-cognito-callback"
  filename         = "lambda/lambda.zip"
  source_code_hash = filebase64sha256("lambda/lambda.zip")
  handler          = "callback.handler"
  runtime          = "nodejs18.x"
  role             = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LabRole"

  environment {
    variables = {
      COGNITO_DOMAIN  = var.cognito_domain
      COGNITO_REGION  = var.aws_region
      CLIENT_ID       = var.cognito_client_id
      CLIENT_SECRET   = var.client_secret != "" ? var.client_secret : (var.client_secret_arn != "" ? data.aws_secretsmanager_secret_version.client_secret[0].secret_string : "")
      REDIRECT_URI    = var.cognito_redirect_uri
      FRONTEND_URL    = var.frontend_url
    }
  }

  tags = {
    Application = var.app_name
  }
}

resource "aws_lambda_function_url" "callback_url" {
  function_name      = aws_lambda_function.cognito_callback.function_name
  authorization_type = "NONE"
}