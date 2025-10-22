data "external" "build_lambda" {
  program = [
    "bash",
    "${path.module}/build_lambda.sh",
    "${path.module}/lambda",
    "${path.module}/lambda.zip"
  ]
}

resource "aws_iam_role" "lambda_exec" {
  name = "${var.app_name}-lambda-exec"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Application = var.app_name
  }
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_secretsmanager_secret_version" "client_secret" {
  count     = var.client_secret_arn != "" ? 1 : 0
  secret_id = var.client_secret_arn
}

resource "aws_lambda_function" "cognito_callback" {
  function_name    = "${var.app_name}-cognito-callback"
  filename         = data.external.build_lambda.result.zip
  source_code_hash = filebase64sha256(data.external.build_lambda.result.zip)
  handler          = "callback.handler"
  runtime          = "nodejs18.x"
  role             = aws_iam_role.lambda_exec.arn

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