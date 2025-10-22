output "vpc_id"          { value = module.vpc.vpc_id }
output "private_subnets" { value = module.vpc.private_subnets }
output "rds_endpoint"    { value = aws_db_instance.postgres.address }
output "api_base_url"    { value = module.api.api_endpoint }

# Ver qué devolvió la lambda de init (cantidad de sentencias aplicadas, etc.)
output "init_schema_result" {
  value = data.aws_lambda_invocation.run_init.result
}
