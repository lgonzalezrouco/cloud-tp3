output "function_arns" {
  value = { for k, f in aws_lambda_function.fn : k => f.arn }
}

output "function_names" {
  value = { for k, f in aws_lambda_function.fn : k => f.function_name }
}
