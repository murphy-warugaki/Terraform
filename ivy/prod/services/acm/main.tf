variable "name" {
  type = "string"
}

variable "domain" {
  type = "string"
}

# route53
data "aws_route53_zone" "this" {
  name = var.domain
}

# ssl証明書
resource "aws_acm_certificate" "this" {
  domain_name = var.domain

  # ドメイン名を追加したい場合
  subject_alternative_names = []

  # ドメインの所有権の検証方法 email or dns
  validation_method = "DNS"

  # リソースを作成してから、リソースを削除する
  # 基本はリソースを削除してから、リソースを作成する
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "this" {
  name       = aws_acm_certificate.this.domain_validation_options[0].resource_record_name
  type       = aws_acm_certificate.this.domain_validation_options[0].resource_record_type
  records    = [aws_acm_certificate.this.domain_validation_options[0].resource_record_value]

  depends_on = [aws_acm_certificate.this]

  zone_id    = data.aws_route53_zone.this.id

  ttl = 60
}

# apply時にSSL証明書の検証が完了するまで待ってくれる
resource "aws_acm_certificate_validation" "this" {
  certificate_arn = aws_acm_certificate.this.arn

  validation_record_fqdns = [aws_route53_record.this.fqdn]
}

output "acm_id" {
  value = aws_acm_certificate.this.id
}

output "acm_arn" {
  value = aws_acm_certificate.this.arn
}
