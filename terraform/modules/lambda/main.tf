# NO se crea IAM acá. Siempre usamos el rol pasado por var.lambda_role.

resource "aws_lambda_function" "fn" {
  for_each         = var.lambda_functions

  function_name    = "${var.name_prefix}-${each.key}"
  role             = var.lambda_role
  handler          = each.value.handler
  runtime          = each.value.runtime
  filename         = each.value.filename
  source_code_hash = filebase64sha256(each.value.filename)

  environment {
    variables = coalesce(each.value.env, {})
  }

  vpc_config {
    subnet_ids         = var.vpc_subnet_ids
    security_group_ids = var.vpc_security_group_ids
  }

  memory_size = 256
  timeout     = 10
}

# Log group por función (opcional pero recomendado)
resource "aws_cloudwatch_log_group" "fn" {
  for_each          = var.lambda_functions
  name              = "/aws/lambda/${aws_lambda_function.fn[each.key].function_name}"
  retention_in_days = 14
}
