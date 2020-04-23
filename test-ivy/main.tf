# security_groups
module "http_sg" {
  source      = "./security_group"
  name        = "http-sg"
  vpc_id      = aws_vpc.example.id
  port        = 80
  cidr_blocks = ["0.0.0.0/0"]
}

module "https_sg" {
  source      = "./security_group"
  name        = "https-sg"
  vpc_id      = aws_vpc.example.id
  port        = 443
  cidr_blocks = ["0.0.0.0/0"]
}

module "http_redirect_sg" {
  source      = "./security_group"
  name        = "http-redirect-sg"
  vpc_id      = aws_vpc.example.id
  port        = 8080
  cidr_blocks = ["0.0.0.0/0"]
}

/*
data "aws_availability_zones" "all" {}

# scale out
resource "aws_autoscaling_policy" "scale_out" {
    name = "CPU-High"
    scaling_adjustment = 1
    adjustment_type = "ChangeInCapacity"
    cooldown = 300
    autoscaling_group_name = aws_autoscaling_group.example.name
}

# scale in
resource "aws_autoscaling_policy" "scale_in" {
    name = "CPU-Low"
    scaling_adjustment = -1
    adjustment_type = "ChangeInCapacity"
    cooldown = 300
    autoscaling_group_name = aws_autoscaling_group.example.name
}

# scale out rule
resource "aws_cloudwatch_metric_alarm" "scale_out" {
    alarm_name = "CPU-High-30"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods = "1"
    # 監視項目
    metric_name = "CPUUtilization"
    namespace = "AWS/EC2"
    period = "300"
    statistic = "Average"
    threshold = "30"
    dimensions = {
        AutoScalingGroupName = aws_autoscaling_group.example.name
    }
    alarm_actions = ["${aws_autoscaling_policy.scale_out.arn}"]
}

# scale in rule
resource "aws_cloudwatch_metric_alarm" "scale_in" {
    alarm_name = "CPU-Low-5"
    comparison_operator = "LessThanThreshold"
    evaluation_periods = "1"
    metric_name = "CPUUtilization"
    namespace = "AWS/EC2"
    period = "300"
    statistic = "Average"
    threshold = "5"
    dimensions = {
        AutoScalingGroupName = aws_autoscaling_group.example.name
    }
    alarm_actions = ["${aws_autoscaling_policy.scale_in.arn}"]
}

# route 53
data "aws_route53_zone" "example" {
   name = "test-ivy.hassyadai.com"
}

resource "aws_route53_record" "example" {
  zone_id = data.aws_route53_zone.example.zone_id
  name    = data.aws_route53_zone.example.name

  # ALIASレコード
  type    = "A"

  alias {
    name                   = aws_elb.example.dns_name
    zone_id                = aws_elb.example.zone_id
    evaluate_target_health = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ssl証明関係
resource "aws_acm_certificate" "example" {
  domain_name               = data.aws_route53_zone.example.name

  # ドメイン名を追加したい場合
  subject_alternative_names = []

  # ドメインの所有権の検証方法 email or dns
  validation_method         = "DNS"

  # リソースを作成してから、リソースを削除する
  lifecycle {
    create_before_destroy = false
  }
}

resource "aws_route53_record" "certificate" {
  name    = aws_acm_certificate.example.domain_validation_options[0].resource_record_name
  type    = aws_acm_certificate.example.domain_validation_options[0].resource_record_type
  records = [aws_acm_certificate.example.domain_validation_options[0].resource_record_value]
  zone_id = data.aws_route53_zone.example.id
  ttl     = 60
}

# apply時にSSL証明書の検証が完了するまで待ってくれる
resource "aws_acm_certificate_validation" "example" {
  certificate_arn         = aws_acm_certificate.example.arn
  validation_record_fqdns = [aws_route53_record.certificate.fqdn]
}

resource "aws_launch_configuration" "example" {
    image_id = "ami-04b2d1589ab1d972c"
    instance_type = "t2.micro"
    security_groups = [
      module.http_sg.security_group_id,
      module.https_sg.security_group_id,
      module.http_redirect_sg.security_group_id,
    ]

    user_data = <<-EOF
                #! /bin/bash
                sudo yum update
                sudo yum install -y httpd
                sudo chkconfig httpd on
                sudo service httpd start
                echo "<h1>hello world</h1>" | sudo tee /var/www/html/index.html
                EOF

    lifecycle {
        create_before_destroy = true
    }
}
# autoscaling
resource "aws_autoscaling_group" "example" {
    launch_configuration = "${aws_launch_configuration.example.id}"
    availability_zones = "${data.aws_availability_zones.all.names}"

    load_balancers = ["${aws_elb.example.name}"]
    health_check_type = "ELB"

    min_size = 2
    max_size = 5

    tag {
        key = "Name"
        value = "ivy-test-asg"
        # 生成されたインスタンスへのタグ付け
        propagate_at_launch = true
    }

    lifecycle {
        create_before_destroy = true
    }
}
*/
