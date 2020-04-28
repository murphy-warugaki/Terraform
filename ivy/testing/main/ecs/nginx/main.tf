variable "name" {
  type = "string"
}

variable "vpc_id" {
  type = "string"
}


variable "https_listener_arn" {
  type = "string"
}

variable "cluster_arn" {
  type = "string"
}

variable "subnet_ids" {
  type = "list"
}

variable "elb" {}
variable "execution_role_arn" {}
variable "security_group_id" {}

locals {
  name = "${var.name}-nginx"
}

# ヘルスチェックを行い、ECSサービスとALBを紐づかせる
resource "aws_lb_target_group" "this" {
  name = local.name
  # ターゲットグループを作成するVPC
  vpc_id = var.vpc_id

  # ALBからECSタスクのコンテナへトラフィックを振り分ける設定
  port        = 80
  protocol    = "HTTP"

  # EC2インスタンスやIPアドレス(Fargate使用時)、Lambda関数などが指定できる
  target_type = "ip"

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
  depends_on = [var.elb]
}

# ALBがリクエストを受けた際、どのターゲットグループへリクエストを受け渡すかの設定
resource "aws_lb_listener_rule" "this" {
  # ルールを追加するリスナー
  listener_arn = var.https_listener_arn
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

# タスク定義
# どんなコンテナをどんな設定で動かすかを定義する
resource "aws_ecs_task_definition" "this" {
  # prefix
  family = local.name
  # 2vCPU
  cpu    = "2048"
  # 4G
  memory = "4096"

  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  container_definitions    = file("./ecs/nginx/container_definitions.json")

  # DockerコンテナがCloudWatch Logsにログを投げられるようにする
  # execution_role_arn       = var.execution_role_arn
}

# ECSサービス
# タスクを管理し, ALBとタスクの架け橋になる
# タスク定義を元にタスク(コンテナ)を立ち上げ、そのコンテナとどのロードバランサ(ターゲットグループ, リスナー)を紐付ける
resource "aws_ecs_service" "this" {
  name       = local.name
  cluster    = var.cluster_arn
  depends_on = [aws_lb_listener_rule.this]

  # 起動するECSタスクのタスク定義
  task_definition = aws_ecs_task_definition.this.arn

  # 維持するタスク数(タスク定義をもとに起動したコンテナをタスクと呼ぶ)
  desired_count = 2

  # Fargateをデータプレーンとして使用する
  launch_type      = "FARGATE"
  platform_version = "1.3.0"

  # ヘルスチェックの猶予時間
  health_check_grace_period_seconds = 60

  # ネットワーク構成
  # ECSタスクへ設定するネットワークの設定
  network_configuration {
    # public ip の割り当て
    assign_public_ip = false
    subnets          = var.subnet_ids
    security_groups  = [var.security_group_id]
  }

  # ECSタスクの起動後に紐付けるALBターゲットグループ
  # ターゲットグループ、コンテナの名前、ポート番号からロードバランサーと紐付け
  # 複数のコンテナをタスクで管理する場合は、最初にLBからリクエストを受け取るコンテナの値を指定
  load_balancer {
      target_group_arn = aws_lb_target_group.this.arn
      # containe_definitionsでnameをnginxにして、ここでもnginxを指定するのがベター
      container_name   = "nginx"
      container_port   = "80"
  }

  lifecycle {
    ignore_changes = [task_definition]
  }
}

output "service_name" {
  value = aws_ecs_service.this.name
}
