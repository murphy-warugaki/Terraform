provider "aws" {
 region = "ap-northeast-1"
}

resource "aws_security_group" "example_ec2" {
 name = "example-ec2"

 ingress {
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
 }

 egress {
  from_port = 0
  to_port   = 0
  protocol  = "-1"
  cidr_blocks = ["0.0.0.0/0"]
 }

}

/*
locals {
 instance_type = "t2.micro"
}

variable "tag_name" {
 default = "terraform_ver_4"
}
*/

variable "env" {}

data "template_file" "httpd_user_data" {
  template = file("./user_data.sh.tpl")

  vars = {
    package = "httpd"
  }
}


resource "aws_instance" "example" {

 //ami = "ami-8e8847f1" centos 7 
 ami = "ami-0f9ae750e8274075b"

 //instance_type = local.instance_type
 //instance_type = “var.env == "prod" ? "m5.large" : "t3.micro" 三項演算子使える

 instance_type = "t2.micro"

 vpc_security_group_ids = [aws_security_group.example_ec2.id]

 // 組み込みのfile関数使える
 // user_data = file("./user_data.sh")
 // テンプレートファイル利用
 user_data = data.template_file.httpd_user_data.rendered

 tags = {
  Name = "terraform_ver_5"
 }
}

output "example_public_dns" {
  value = aws_instance.example.public_dns
}

output "example_instance_id" {
  value = aws_instance.example.id
}
