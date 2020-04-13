module "dev_server" {
  source        = "./http_server"
  instance_type = "t2.micro"
}
 
output "public_dns" {
  value = module.dev_server.public_dns
}
