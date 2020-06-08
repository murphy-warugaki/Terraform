############################
# data source
############################

locals {
 name          = "prod-ivy"
 domain        = "chat-boost.hassyadai.com"
 s3_alb_log_id = "prod-ivy-alb-log"
 client_id     = 1
}

# vpc
data "aws_vpc" "this" {
  filter {
    name   = "tag:Name"
    values = [local.name]
  }
}

# security_group
data "aws_security_group" "mysql" {
  filter {
    name   = "tag:Name"
    values = ["${local.name}-http-sg"]
  }
}

data "aws_security_group" "redis" {
  filter {
    name   = "tag:Name"
    values = ["${local.name}-https-sg"]
  }
}

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

data "aws_security_group" "ssh" {
  filter {
    name   = "tag:Name"
    values = ["${local.name}-ssh-sg"]
  }
}

# subnets
### private
data "aws_subnet" "private_az1" {
  filter {
    name   = "tag:Name"
    values = ["${local.name}-private_1a"]
  }
}

data "aws_subnet" "private_az2" {
  filter {
    name   = "tag:Name"
    values = ["${local.name}-private_1c"]
  }
}

data "aws_subnet" "private_az3" {
  filter {
    name   = "tag:Name"
    values = ["${local.name}-private_1d"]
  }
}

### public
data "aws_subnet" "public_az1" {
  filter {
    name   = "tag:Name"
    values = ["${local.name}-1a"]
  }
}

data "aws_subnet" "public_az2" {
  filter {
    name   = "tag:Name"
    values = ["${local.name}-1c"]
  }
}

data "aws_subnet" "public_az3" {
  filter {
    name   = "tag:Name"
    values = ["${local.name}-1d"]
  }
}

# az all
data "aws_availability_zones" "all" {}

# alb
data "aws_lb" "this" {
  name = local.name
}

############################
# resource source
############################

# rds
module "rds" {
  source = "./rds"

  vpc_id                  = data.aws_vpc.this.id
  mysql_security_group_id = data.aws_security_group.mysql.id
  redis_security_group_id = data.aws_security_group.redis.id
  subnet_ids              = [
      data.aws_subnet.private_az1.id,
      data.aws_subnet.private_az2.id,
      data.aws_subnet.private_az3.id,
  ]

  name            = "${local.name}-${local.client_id}"
  master_username = "root"
  master_password = "secret12345"
}

############################

# autoscaling
# このリソースは別管理の方がよき？
resource "aws_launch_configuration" "this" {
  name_prefix = "${local.name}-t2micro-"
  
  # ami
  image_id                    = "ami-04b2d1589ab1d972c" 
  instance_type               = "t2.small"
  key_name                    = "hassyadai"

  security_groups = [
    data.aws_security_group.http.id,
    data.aws_security_group.https.id,
    data.aws_security_group.ssh.id
  ]

  user_data = file("./apache.sh")

  lifecycle {
    create_before_destroy = true
  }
}

# ヘルスチェックを行い、ECSサービスとALBを紐づかせる
resource "aws_lb_target_group" "this" {
  name = "${local.name}-${local.client_id}-tg"
  # ターゲットグループを作成するVPC
  vpc_id = data.aws_vpc.this.id

  # ALBからECSタスクのコンテナへトラフィックを振り分ける設定
  port        = 80
  protocol    = "HTTP"

  # ターゲットを登録解除する前にALBが待機する時間
  deregistration_delay = 300

  # コンテナへの死活監視設定
  health_check {
    # ヘルスチェックで使用するパス
    path                = "/"
    # 正常判定を行うまでのヘルスチェック実行回数
    healthy_threshold   = 2
    # 異常判定を行うまでのヘルスチェック実行回数
    unhealthy_threshold = 2
    # ヘルスチェックのタイムアウト時間（秒）
    timeout             = 3
    # ヘルスチェックの実行間隔（秒）
    interval            = 30
    # 正常判定を行うために使用するHTTPステータスコード
    matcher             = 200
    # traffic-portを使うと上で定義したポートが利用される
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  # ALBとターゲットグループを同時に作成するとエラーになるので依存関係を持たせる
  depends_on = [data.aws_lb.this]
}

resource "aws_autoscaling_group" "this" {
  name                 = "${local.name}-${local.client_id}-asg"
  launch_configuration = aws_launch_configuration.this.id
  availability_zones   = data.aws_availability_zones.all.names

  force_delete        = true
  health_check_type   = "ELB"
  # target_group_arns   = [aws_lb_target_group.this.arn]
  vpc_zone_identifier = [
      data.aws_subnet.public_az1.id,
      data.aws_subnet.public_az2.id,
      data.aws_subnet.public_az3.id
  ]

  min_size = 1
  max_size = 5

  tag {
      key = "Name"
      value = "${local.name}-${local.client_id}"
      propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_attachment" "this" {
  autoscaling_group_name = aws_autoscaling_group.this.id
  alb_target_group_arn   = aws_lb_target_group.this.arn
}

data "aws_lb_listener" "this" {
  load_balancer_arn = data.aws_lb.this.arn
  port              = 443
}

# ALBがリクエストを受けた際、どのターゲットグループへリクエストを受け渡すかの設定
resource "aws_lb_listener_rule" "this" {
  # ルールを追加するリスナー
  listener_arn = data.aws_lb_listener.this.arn
  priority     = 100

  # 受け取ったトラフィックをターゲットグループへ受け渡す
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }

  # ターゲットグループへ受け渡すトラフィックの条件
  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}
