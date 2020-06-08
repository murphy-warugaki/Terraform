locals {
 name          = "prod-ivy"
 domain        = "chat-boost.hassyadai.com"
 s3_alb_log_id = "prod-ivy-alb-log"
}

# vpc
data "aws_vpc" "this" {
  filter {
    name   = "tag:Name"
    values = [local.name]
  }
}

# acm
data "aws_acm_certificate" "this" {
  domain = local.domain
}

# public subnets
data "aws_subnet" "az1" {
  filter {
    name   = "tag:Name"
    values = ["${local.name}-1a"]
  }
}

data "aws_subnet" "az2" {
  filter {
    name   = "tag:Name"
    values = ["${local.name}-1c"]
  }
}

data "aws_subnet" "az3" {
  filter {
    name   = "tag:Name"
    values = ["${local.name}-1d"]
  }
}

# security_group
data "aws_security_group" "http" {
  filter {
    name   = "tag:Name"
    values = ["${local.name}-http-sg"]
  }
}

data "aws_security_group" "https" {
  filter {
    name   = "tag:Name"
    values = ["${local.name}-https-sg"]
  }
}

module "alb" {
  source  = "./alb"
  name    = local.name
  vpc_id  = data.aws_vpc.this.id
  s3_id   = local.s3_alb_log_id
  domain  = local.domain
  acm_arn = data.aws_acm_certificate.this.arn

  public_subnet_ids = [
    data.aws_subnet.az1.id,
    data.aws_subnet.az2.id,
    data.aws_subnet.az3.id,
  ]

  security_group_ids = [
    data.aws_security_group.http.id,
    data.aws_security_group.https.id
  ]
}