locals {
 name          = "pj-name"
 domain        = "pj-name.com"
 s3_alb_log_id = "pj-name-alb-log"
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

data "aws_security_group" "ssh" {
  filter {
    name   = "tag:Name"
    values = ["${local.name}-ssh-sg"]
  }
}

##############################################
# autoscaling 設定ファイル
# 新たに設定ファイルを足す際は、消さずに追加してください
##############################################

resource "aws_launch_configuration" "ver_1" {
  name_prefix = "${local.name}-amzn2-t2small-"
  
  # ami amzn2-ami-hvm-2.0.20200520.1-x86_64-gp2
  image_id      = "ami-0a1c2ec61571737db" 
  instance_type = "t2.small"
  key_name      = "hassyadai"
  associate_public_ip_address = true

  security_groups = [
    data.aws_security_group.http.id,
    data.aws_security_group.https.id,
    data.aws_security_group.ssh.id
  ]
  
  # s3で呼び出したい
  user_data = file("./setup.sh")

  lifecycle {
    create_before_destroy = true
  }
}