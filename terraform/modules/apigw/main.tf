########################################
# API Gateway HTTP API (v2)
########################################
resource "aws_apigatewayv2_api" "http" {
  name          = "${var.name}-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"] 
    allow_methods = ["GET","POST","OPTIONS"]
    allow_headers = ["Authorization","Content-Type"]
    expose_headers = ["Content-Length","Content-Type"]
    max_age = 3600
  }
}


########################################
# (Opcional) JWT Authorizer
########################################
resource "aws_apigatewayv2_authorizer" "jwt" {
  count            = var.jwt_authorizer == null ? 0 : 1
  api_id           = aws_apigatewayv2_api.http.id
  name             = "jwt-auth"
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]

  jwt_configuration {
    audience = var.jwt_authorizer.audiences
    issuer   = var.jwt_authorizer.issuer
  }
}

########################################
# Integraciones (Lambda proxy)
########################################
resource "aws_apigatewayv2_integration" "route_integration" {
  for_each               = var.routes
  api_id                 = aws_apigatewayv2_api.http.id
  integration_type       = "AWS_PROXY"
  integration_uri        = each.value.lambda_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

########################################
# Flags locales (uso de JWT) y authorizer_id
########################################
locals {
  use_jwt       = var.jwt_authorizer != null
  authorizer_id = local.use_jwt ? aws_apigatewayv2_authorizer.jwt[0].id : null
}

########################################
# Rutas (auth por ruta con fallback a JWT/NONE global)
########################################
resource "aws_apigatewayv2_route" "route" {
  for_each = var.routes

  api_id    = aws_apigatewayv2_api.http.id
  route_key = each.value.route_key
  target    = "integrations/${aws_apigatewayv2_integration.route_integration[each.key].id}"

  # Si el item tiene "auth", usarlo; si no, usar JWT si existe, caso contrario NONE
  authorization_type = lookup(each.value, "auth", (local.use_jwt ? "JWT" : "NONE"))
  authorizer_id      = (
    local.use_jwt && lookup(each.value, "auth", "JWT") == "JWT"
  ) ? local.authorizer_id : null
}

########################################
# Stage $default con auto_deploy
########################################
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http.id
  name        = "$default"
  auto_deploy = true
}

########################################
# Extraer el path de "METHOD /path"
########################################
# Ej.: "GET /api/products" -> "/api/products"
locals {
  route_path = {
    for k, r in var.routes :
    k => trimspace(join(
      " ",
      slice(
        split(" ", r.route_key),
        1,
        length(split(" ", r.route_key))
      )
    ))
  }
}

########################################
# Permisos de invocación Lambda por ruta
########################################
# HTTP API execution_arn: arn:aws:execute-api:region:acct:api-id
# Usamos "*/*{path}" -> ej. "/*/*/api/products"
resource "aws_lambda_permission" "invoke" {
  for_each      = var.routes
  statement_id  = "AllowInvoke-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = each.value.lambda_arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http.execution_arn}/*/*${local.route_path[each.key]}"
}

