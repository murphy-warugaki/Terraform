locals {
 name          = "prod-ivy-1"
 domain        = "test-ivy.hassyadai.com"
 s3_alb_log_id = "test-ivy-alb-log"
}

# vpc
data "aws_vpc" "this" {
  filter {
    name   = "tag:Name"
    values = [local.name]
  }
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

# private subnets
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

# security_groups
module "http_sg" {
  source      = "./security_group"
  name        = "http-sg"
  vpc_id      = data.aws_vpc.this.id
  port        = 80
  cidr_blocks = ["0.0.0.0/0"]
}

module "https_sg" {
  source      = "./security_group"
  name        = "https-sg"
  vpc_id      = data.aws_vpc.this.id
  port        = 443
  cidr_blocks = ["0.0.0.0/0"]
}

module "nginx_sg" {
  source      = "./security_group"
  name        = "nginx-sg"
  vpc_id      = data.aws_vpc.this.id
  port        = 80
  cidr_blocks = [data.aws_vpc.this.cidr_block]
}

module "mysql_sg" {
  source      = "./security_group"
  name        = "mysql-sg"
  vpc_id      = data.aws_vpc.this.id
  port        = 3306
  cidr_blocks = [data.aws_vpc.this.cidr_block]
}

module "redis_sg" {
  source      = "./security_group"
  name        = "redis-sg"
  vpc_id      = data.aws_vpc.this.id
  port        = 6379
  cidr_blocks = [data.aws_vpc.this.cidr_block]
}

module "acm" {
  source = "./acm"
  name   = local.name
  domain = local.domain
}

module "elb" {
  source  = "./elb"
  name    = local.name
  vpc_id  = data.aws_vpc.this.id
  s3_id   = local.s3_alb_log_id
  domain  = local.domain
  acm_arn = module.acm.acm_arn

  public_subnet_ids = [
    data.aws_subnet.az1.id,
    data.aws_subnet.az2.id,
    data.aws_subnet.az3.id,
  ]

  security_group_ids = [
    module.http_sg.security_group_id,
    module.https_sg.security_group_id
  ]
}

module "rds" {
  source = "./rds"

  vpc_id            = data.aws_vpc.this.id
  mysql_security_group_id = module.mysql_sg.security_group_id
  redis_security_group_id = module.redis_sg.security_group_id
  subnet_ids        = [
      data.aws_subnet.private_az1.id,
      data.aws_subnet.private_az2.id,
      data.aws_subnet.private_az3.id,
  ]

  name            = "${local.name}-id-1" 
  master_username = "root"
  master_password = "secret12345"
}

module "ecs_cluster" {
  source = "./ecs/cluster"
  name = local.name
}

/*
# ECSタスク実行IAMロールの定義:
module "ecs_task_execution_role" {
  source     = "./iam_role"
  name       = var.name
  # このiam_roleをecsで使うことを宣言する
  identifier = "ecs-tasks.amazonaws.com"
  policy     = data.aws_iam_policy_document.ecs_task_execution.json
}

#  ECSタスク実行IAMロールのポリシードキュメントの定義
data "aws_iam_policy_document" "ecs_task_execution" {
  # 既存のポリシーを継承
  source_json = data.aws_iam_policy.ecs_task_execution_role_policy.policy

  statement {
    effect    = "Allow"
    actions   = ["ssm:GetParameters", "kms:Decrypt"]
    resources = ["*"]
  }
}

data "aws_iam_policy" "ecs_task_execution_role_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

module "ecs_laravel" {
  source = "./ecs/laravel"
  elb    = module.elb.lb_obj
  name   = var.name

  cluster_arn        = module.ecs_cluster.cluster_arn
  https_listener_arn = module.elb.https_listener_arn
  execution_role_arn = module.ecs_task_execution_role.iam_role_arn

  vpc_id             = data.aws_vpc.testing.id
  security_group_id  = module.http_sg.security_group_id
  subnet_ids         = [
      data.aws_subnet.private_az1.id,
      data.aws_subnet.private_az2.id,
      data.aws_subnet.private_az3.id,
  ]

  db_host     = "myhost"
  db_username = "myusername"
  db_password = "mypassword"
  db_database = "mydatabase"
  app_key     = "base64:ROM9KOi7mwGxr2XFwfgCWeejBhLIq5hXY8AEk91ePCk="
}

module "ecs_nginx" {
  source = "./ecs/nginx"
  elb    = module.elb.lb_obj
  name   = var.name


  cluster_arn        = module.ecs_cluster.cluster_arn
  https_listener_arn = module.elb.https_listener_arn
  execution_role_arn = module.ecs_task_execution_role.iam_role_arn

  vpc_id             = data.aws_vpc.testing.id
  security_group_id  = module.nginx_sg.security_group_id
  subnet_ids         = [
      data.aws_subnet.private_az1.id,
      data.aws_subnet.private_az2.id,
      data.aws_subnet.private_az3.id,
  ]
}

data "aws_iam_policy" "ec2_for_ssm" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}
data "aws_iam_policy_document" "codepipeline" {
  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
      "ecs:DescribeServices",
      "ecs:DescribeTaskDefinition",
      "ecs:DescribeTasks",
      "ecs:ListTasks",
      "ecs:RegisterTaskDefinition",
      "ecs:UpdateService",
      "iam:PassRole",
    ]
  }
}
# session manager
data "aws_iam_policy_document" "ec2_for_ssm" {
  source_json = data.aws_iam_policy.ec2_for_ssm.policy

  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
      "kms:Decrypt",
    ]
  }
}

# docker imageを保管するリポジトリ
resource "aws_ecr_repository" "example" {
  name = "test-ivy"
}

resource "aws_ecr_lifecycle_policy" "example" {
  repository = aws_ecr_repository.example.name

  policy = <<EOF
  {
    "rules": [
      {
        "rulePriority": 1,
        "description": "Keep last 30 release tagged images",
        "selection": {
          "tagStatus": "tagged",
          "tagPrefixList": ["release"],
          "countType": "imageCountMoreThan",
          "countNumber": 30
        },
        "action": {
          "type": "expire"
        }
      }
    ]
  }
EOF
}

# CodeBuildサービスロールのポリシードキュメントの定義
data "aws_iam_policy_document" "codebuild" {
  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:DescribeImages",
      "ecr:BatchGetImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage",
    ]
  }
}

# CodeBuild用のIAMロール
module "codebuild_role" {
  source     = "./iam_role"
  name       = "codebuild"
  identifier = "codebuild.amazonaws.com"
  policy     = data.aws_iam_policy_document.codebuild.json
}

# CodeBuildプロジェクト
# CodePipelineから起動する
resource "aws_codebuild_project" "example" {
  name         = "test-ivy"
  service_role = module.codebuild_role.iam_role_arn

  source {
    type = "CODEPIPELINE"
  }

  artifacts {
    type = "CODEPIPELINE"
  }

  # ビルド環境
  environment {
    type            = "LINUX_CONTAINER"
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/ubuntu-base:14.04"
    # docker コマンドを使うので権限付与
    privileged_mode = true
  }
}


module "codepipeline_role" {
  source     = "./iam_role"
  name       = "codepipeline"
  identifier = "codepipeline.amazonaws.com"
  policy     = data.aws_iam_policy_document.codepipeline.json
}

# 名前がユニークじゃないといけないので、dataで読んだ方がいいかも
resource "aws_s3_bucket" "artifact" {
  bucket = "test-ivy-artifact-pragmatic-terraform-on-aws"

  lifecycle_rule {
    enabled = true

    expiration {
      days = "180"
    }
  }
}

resource "aws_codepipeline" "example" {
  name     = "test-ivy"
  role_arn = module.codepipeline_role.iam_role_arn

  # githubからソースコードを取得する
  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = 1
      output_artifacts = ["Source"]

      configuration = {
        Owner                = "hassyadai"
        Repo                 = "Ivy"
        Branch               = "feature/nishimoto"
        PollForSourceChanges = false
      }
    }
  }

  # codebuildを実行してECRにDocker Imageをpushする
  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = 1
      input_artifacts  = ["Source"]
      output_artifacts = ["Build"]

      configuration = {
        ProjectName = aws_codebuild_project.example.id
      }
    }
  }

  # ECSへdockerイメージをデプロイする
  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      version         = 1
      input_artifacts = ["Build"]

      configuration = {
        ClusterName = module.ecs_cluster.cluster_name
        ServiceName = module.ecs_nginx.service_name
        FileName    = "imagedefinitions.json"
      }
    }
  }

  artifact_store {
    location = aws_s3_bucket.artifact.id
    type     = "S3"
  }
}

resource "aws_codepipeline_webhook" "example" {
  name            = "test-ivy"
  target_pipeline = aws_codepipeline.example.name
  target_action   = "Source"
  authentication  = "GITHUB_HMAC"

  authentication_configuration {
    secret_token = "VeryRandomStringMoreThan20Byte!"
  }

  # 起動条件
  filter {
    json_path    = "$.ref"
    match_equals = "refs/heads/{Branch}"
  }
}

provider "github" {
  organization = "hassyadai"
}

resource "github_repository_webhook" "example" {
  repository = "Ivy"
  # name       = "web"

  configuration {
    url          = aws_codepipeline_webhook.example.url
    # secret_tokenと同じ値
    secret       = "VeryRandomStringMoreThan20Byte!"
    content_type = "json"
    insecure_ssl = false
  }

  events = ["push"]
}

module "ec2_for_ssm_role" {
  source     = "./iam_role"
  name       = "ec2-for-ssm"
  identifier = "ec2.amazonaws.com"
  policy     = data.aws_iam_policy_document.ec2_for_ssm.json
}

# profileをEC2インスタンスへ紐付ける
resource "aws_iam_instance_profile" "ec2_for_ssm" {
  name = "ec2-for-ssm"
  role = module.ec2_for_ssm_role.iam_role_name
}

# オペレーション用EC2インスタンス
resource "aws_instance" "example_for_operation" {
  # Amazon Linux 2
  ami                  = "ami-0f9ae750e8274075b"
  instance_type        = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.ec2_for_ssm.name
  subnet_id            = data.aws_subnet.private_az1.id
  user_data            = file("./user_data.sh")
  tags = {
   Name = "ecs_for_operation"
  }
}

output "operation_instance_id" {
  value = aws_instance.example_for_operation.id
}

# オペレーションログを保存するS3バケット
resource "aws_s3_bucket" "operation" {
  bucket = "test-ivy-operation-pragmatic-terraform-on-aws"

  lifecycle_rule {
    enabled = true

    expiration {
      days = "180"
    }
  }
}

# CloudWatch Logsログ保存先
resource "aws_cloudwatch_log_group" "operation" {
  name              = "/operation"
  retention_in_days = 180
}

resource "aws_ssm_document" "session_manager_run_shell" {
  # nameがこれで固定
  name            = "SSM-SessionManagerRunShell"
  document_type   = "Session"
  document_format = "JSON"

  content = <<EOF
  {
    "schemaVersion": "1.0",
    "description": "Document to hold regional settings for Session Manager",
    "sessionType": "Standard_Stream",
    "inputs": {
      "s3BucketName": "${aws_s3_bucket.operation.id}",
      "cloudWatchLogGroupName": "${aws_cloudwatch_log_group.operation.name}"
    }
  }
EOF
}
*/
/*
terraformブロックを定義することでTerraformが現在管理しているリソース情報をリモートで管理することができます。
これによりバックアップや多人数開発が可能になるため、基本的にterraformブロックは使用することが好ましいです。
AWSであればS3を、GCPであればGCSを使用すると良いでしょう。また、terraformブロックで指定するS3(GCS)は先に作成する必要があります。
terraform {
  backend "s3" {
    bucket = "<YOUR S3 BUCKET>"
    key    = "terraform.tfstate"
    region = "ap-northeast-1"
  }
}

variable "env" {
  description = "環境名"
  default     = "dev"
}

条件分岐は三項演算子として記述することが可能です。
1環境しか作成しない場合は基本使用しませんが、複数環境作成する場合環境依存になってしまう箇所が発生します。その環境によって異なる値を振り分けるために使用することが多いです。

locals {
  cidr = "${ env == "prd" ? "10.0.0.0/16" : "172.16.0.0/16" }"
}

resource "aws_vpc" "main" {
  cidr_block = "${locals.cidr}"
}
*/
