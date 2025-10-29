resource "aws_apigatewayv2_api" "callback_api" {
  name          = "${var.app_name}-callback-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id           = aws_apigatewayv2_api.callback_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${aws_lambda_function.cognito_callback.arn}/invocations"
}

resource "aws_apigatewayv2_route" "callback_route" {
  api_id    = aws_apigatewayv2_api.callback_api.id
  route_key = "GET /callback"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_stage" "prod" {
  api_id      = aws_apigatewayv2_api.callback_api.id
  name        = "prod"
  auto_deploy = true
}

resource "aws_lambda_permission" "allow_apigw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cognito_callback.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.callback_api.execution_arn}/*/*"

  depends_on = [
    aws_apigatewayv2_api.callback_api,
    aws_apigatewayv2_integration.lambda_integration,
    aws_lambda_function.cognito_callback
  ]
}

output "callback_url" {
  description = "URL pública para el callback de Cognito"
  value       = "${aws_apigatewayv2_api.callback_api.api_endpoint}/${aws_apigatewayv2_stage.prod.name}/callback"
}