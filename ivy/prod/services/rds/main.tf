variable "name" {
  type = "string"
}

variable "vpc_id" {
  type = "string"
}

variable "mysql_security_group_id" {
  type = "string"
}

variable "redis_security_group_id" {
  type = "string"
}

variable "subnet_ids" {
  type = "list"
}

variable "master_username" {
  type = "string"
}

variable "master_password" {
  type = "string"
}

locals {
  name       = "${var.name}-mysql"
  redis_name = "${var.name}-redis"
}
/*
RDSやElastiCacheのapplyには時間がかかる。
一回applyするだけで10分以上、場合によっては30分超えということもあり。

低スペックなT2系、T3系のインスタンスタイプで作成しようとすると、apply時間が上振れやすい。
Terraformで試行錯誤するときには、ケチケチせずにそれなりのインスタンスタイプを使用する。
*/

# MySQLのmy.cnfファイルに定義するようなデータベースの設定は、DBパラメータグループに記述
resource "aws_db_parameter_group" "this" {
  name   = local.name
  # エンジン名とバージョンをあわせた値
  family = "mysql5.7"

  parameter {
    name  = "character_set_database"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }
}

# データベースエンジンにオプション機能を追加できる
# MySQLでは「MariaDB監査プラグイン」と「MySQL MEMCACHED」がサポートされている
resource "aws_db_option_group" "this" {
  name                 = local.name
  engine_name          = "mysql"
  major_engine_version = "5.7"

  # MariaDB監査プラグインは、ユーザのログオンや実行したクエリなどのアクティビティを記録するためのプラグイン
  option {
    option_name = "MARIADB_AUDIT_PLUGIN"
  }

  timeouts {
    delete = "5m"
  }
}

# データベースを稼働させるサブネット
resource "aws_db_subnet_group" "this" {
  name        = local.name
  description = local.name
  subnet_ids  = var.subnet_ids
}

# KMS (Key Management Service) : 暗号鍵を管理するマネージドサービス
resource "aws_kms_key" "db" {
  description             = "DB Master Key"
  # ローテーション頻度は年に一回
  enable_key_rotation     = false
  # falseにすると、カスタマーマスターキーを無効化できる
  is_enabled              = true
  # カスタマーマスターキーの削除待機期間
  deletion_window_in_days = 30
}

# エイリアスを設定し、どういう用途で使われているか識別しやすくする
resource "aws_kms_alias" "db" {
  name          = "alias/db-${local.name}"
  target_key_id = aws_kms_key.db.key_id
}

resource "aws_db_instance" "this" {
  # データベースのエンドポイントで使う識別子
  identifier                 = local.name
  # エンジン名
  engine                     = "mysql"
  engine_version             = "5.7.23"
  instance_class             = "db.t3.small"
  # ディスク容量
  allocated_storage          = 20
  # 「汎用SSD」か「プロビジョンドIOPS」を設定
  # gp2は「汎用SSD」
  storage_type               = "gp2"
  storage_encrypted          = true
  # kms_key_idに使用するKMSの鍵を指定すると、ディスク暗号化が有効になる
  # なお、デフォルトAWS KMS暗号化鍵を使用すると、アカウントをまたいだスナップショットの共有ができなくなる
  kms_key_id                 = aws_kms_key.db.arn
  username                   = var.master_username
  password                   = var.master_password
  multi_az                   = true
  # VPC外からのアクセスを遮断
  publicly_accessible        = false
  # バックアップのタイミング。UTC
  backup_window              = "09:10-09:40"
  # バックアップ期間。最大35日
  backup_retention_period    = 30
  # メンテナンスタイミング。UTC
  maintenance_window         = "mon:10:10-mon:10:40"
  # 自動マイナーバージョンのupdate
  auto_minor_version_upgrade = false
  # 削除保護
  deletion_protection        = false
  # インスタンス削除時にスナップショットを作成しない時はtrue
  skip_final_snapshot        = true
  # skip_final_snapshotがfalseの時に必要
  # final_snapshot_identifier  = 
  port                       = 3306
  # RDSの変更を即時に変更させない
  apply_immediately          = false
  vpc_security_group_ids     = [var.mysql_security_group_id]
  parameter_group_name       = aws_db_parameter_group.this.name
  option_group_name          = aws_db_option_group.this.name
  db_subnet_group_name       = aws_db_subnet_group.this.name

  lifecycle {
    ignore_changes = [password]
  }
}

resource "aws_elasticache_parameter_group" "this" {
  name   = local.redis_name
  family = "redis5.0"

  # クラスタモード無効
  parameter {
    name  = "cluster-enabled"
    value = "no"
  }
}

resource "aws_elasticache_subnet_group" "this" {
  name       = local.redis_name
  subnet_ids = var.subnet_ids
}

resource "aws_elasticache_replication_group" "this" {
  # Redisのエンドポイントで使う識別子
  replication_group_id          = local.redis_name
  replication_group_description = "Cluster Disabled"
  # 「memcached」か「redis」を設定
  engine                        = "redis"
  engine_version                = "5.0.3"
  # ノード数の指定。ノード数はプライマリノードとレプリカノードの合計値
  # たとえば「3」を指定した場合は、プライマリノードが1つ、レプリカノードが2つになる
  number_cache_clusters         = 1
  # 参照：https://docs.aws.amazon.com/ja_jp/AmazonElastiCache/latest/red-ug/CacheNodes.SupportedTypes.html
  node_type                     = "cache.m3.medium"
  # スナップショットの作成タイミング
  snapshot_window               = "09:10-10:10"
  # スナップショットの保持期間
  snapshot_retention_limit      = 7
  # メンテナンスのタイミング
  maintenance_window            = "mon:10:40-mon:11:40"
  # 自動フェイルオーバーが有効
  automatic_failover_enabled    = false
  port                          = 6379
  # 予期せぬダウンタイムを避けるため、falseに設定
  apply_immediately             = false
  security_group_ids            = [var.redis_security_group_id]
  parameter_group_name          = aws_elasticache_parameter_group.this.name
  subnet_group_name             = aws_elasticache_subnet_group.this.name
}

output "mysql_endpoint" {
  value = aws_db_instance.this.endpoint
}