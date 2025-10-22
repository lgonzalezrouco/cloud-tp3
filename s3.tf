module "s3_bucket" {
  source      = "./modules/s3"
  bucket_name = "matchmarket-testing-emi"
  tags = {
    Owner = var.app_name
  }
}

