locals {
 name          = "pj-name"
 domain        = "pj-name.com"
 s3_alb_log_id = "pj-name-alb-log"
}

# vpc
data "aws_vpc" "this" {
  filter {
    name   = "tag:Name"
    values = [local.name]
  }
}

# security_groups
module "http_sg" {
  source      = "./rule"
  name        = "${local.name}-http-sg"
  vpc_id      = data.aws_vpc.this.id
  port        = 80
  cidr_blocks = ["0.0.0.0/0"]
}

module "https_sg" {
  source      = "./rule"
  name        = "${local.name}-https-sg"
  vpc_id      = data.aws_vpc.this.id
  port        = 443
  cidr_blocks = ["0.0.0.0/0"]
}

module "nginx_sg" {
  source      = "./rule"
  name        = "${local.name}-nginx-sg"
  vpc_id      = data.aws_vpc.this.id
  port        = 80
  cidr_blocks = [data.aws_vpc.this.cidr_block]
}

module "mysql_sg" {
  source      = "./rule"
  name        = "${local.name}-mysql-sg"
  vpc_id      = data.aws_vpc.this.id
  port        = 3306
  cidr_blocks = [data.aws_vpc.this.cidr_block]
}

module "redis_sg" {
  source      = "./rule"
  name        = "${local.name}-redis-sg"
  vpc_id      = data.aws_vpc.this.id
  port        = 6379
  cidr_blocks = [data.aws_vpc.this.cidr_block]
}

module "ssh_sg" {
  source      = "./rule"
  name        = "${local.name}-ssh-sg"
  vpc_id      = data.aws_vpc.this.id
  port        = 22
  cidr_blocks = ["0.0.0.0/0"]
}
