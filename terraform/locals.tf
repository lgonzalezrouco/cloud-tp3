locals {
  db_env = {
    PGHOST     = aws_db_instance.postgres.address
    PGPORT     = "5432"
    PGDATABASE = var.db_name
    PGUSER     = var.db_username
    PGPASSWORD = var.db_password
  }
  api_routes = {
    get_products = {
      route_key  = "GET /api/products"
      lambda_arn = module.lambda.function_arns["list_products"]
      auth       = "NONE"
    }
    get_product = {
      route_key  = "GET /api/products/{id}"
      lambda_arn = module.lambda.function_arns["get_product"]
      auth       = "NONE"
    }
    post_products = {
      route_key  = "POST /api/products"
      lambda_arn = module.lambda.function_arns["create_product"]
      auth       = "JWT"
    }
    post_showrooms = {
      route_key  = "POST /showrooms"
      lambda_arn = module.lambda.function_arns["create_showroom"]
      auth       = "JWT"   
    }
    post_users = {
      route_key  = "POST /users"
      lambda_arn = module.lambda.function_arns["create_user"]
      auth       = "JWT"   
    }
  }
  lambda_functions = {

    create_product = {
      filename = "${path.module}/lambda_zips/create_product.zip"
      handler  = "app.handler"
      runtime  = "python3.12"
      env = local.db_env
    }
    create_showroom = {
      filename = "${path.module}/lambda_zips/create_store.zip"
      handler  = "app.handler"
      runtime  = "python3.12"
      env = local.db_env
    }
    create_user = {
      filename = "${path.module}/lambda_zips/create_user.zip"
      handler  = "app.handler"
      runtime  = "python3.12"
      env = local.db_env
    }
    list_products = {
      filename = "${path.module}/lambda_zips/list_products.zip"
      handler  = "app.handler"
      runtime  = "python3.12"
      env = local.db_env
    }
    get_product = {
      filename = "${path.module}/lambda_zips/get_product.zip"
      handler  = "app.handler"
      runtime  = "python3.12"
      env = local.db_env
    }
    init_schema = {
      filename = "${path.module}/lambda_zips/init_schema.zip"
      handler  = "app.handler"
      runtime  = "python3.12"
      env = local.db_env
    }
  }
}