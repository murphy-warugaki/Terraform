module "alb_log" {
  source      = "./bucket"
  bucket_name = "test-ivy-alb-log"
}

output "s3_id" {
  value = module.alb_log.s3_id
}

