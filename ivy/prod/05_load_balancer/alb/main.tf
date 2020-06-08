variable "name" {
  type = "string"
}

variable "vpc_id" {
  type = "string"
}

variable "s3_id" {
  type = "string"
}

variable "domain" {
  type = "string"
}

variable "acm_arn" {
  type = "string"
}

variable "public_subnet_ids" {
  type = "list"
}

variable "security_group_ids" {
  type = "list"
}

resource "aws_lb" "this" {
  # ALB or NLB (network)
  load_balancer_type = "application"
  name               = var.name
  # second
  idle_timeout       = 60

  # for internet or only vpc. this time development is false , because internet
  internal           = false

  # protect for production 削除するときは一度falseにしてapply
  enable_deletion_protection = false

  security_groups = var.security_group_ids
  subnets         = var.public_subnet_ids

  # ログ保持するか確認
  access_logs {
    bucket  = var.s3_id
    enabled = true
  }

  tags = {
    Name = local.name
  }
}

# ALBに登録されているDNSへのアクセスを紐付ける
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = "80"
  protocol          = "HTTP"

/*
  forward - リクエストを別のターゲットグループに転送
  fixed-response - 固定のHTTPレスポンスを応答
  redirect - 別のURLにリダイレクト”
*/
  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  # 古い物を削除してから新しいリソースを削除する
  lifecycle {
    create_before_destroy = false
  }
}

resource "aws_lb_listener" "https" {
  port     = "443"
  protocol = "HTTPS"

  load_balancer_arn = aws_lb.this.arn
  certificate_arn   = var.acm_arn
  ssl_policy        = "ELBSecurityPolicy-2016-08"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      status_code  = "200"
      message_body = "ok"
    }
  }
}

data "aws_route53_zone" "this" {
  name         = var.domain
  private_zone = false
}

resource "aws_route53_record" "this" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = data.aws_route53_zone.this.name

  # ALIASレコード
  type = "A"

  alias {
    name                   = aws_lb.this.dns_name
    zone_id                = aws_lb.this.zone_id
    evaluate_target_health = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

/*
output "lb_obj" {
  value = aws_lb.this
}

output "https_listener_arn" {
  value = aws_lb_listener.https.arn
}
*/