provider "aws" {
  region = "ap-northeast-1"
}

resource "aws_launch_configuration" "hoge" {
  image_id = "ami-04b2d1589ab1d972c" # ami
  instance_type = "t2.micro"
  security_groups = ["${aws_security_group.instance.id}"]

  user_data = <<EOF
                #! /bin/bash
                sudo yum update
                sudo yum install -y httpd
                sudo chkconfig httpd on
                sudo service httpd start
                echo "<h1>hello world</h1>" | sudo tee /var/www/html/index.html
EOF

  lifecycle {
    create_before_destroy = false
  }
}

resource "aws_security_group" "instance" {
    name = "terraform-example-instance"
    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 追加
  lifecycle {
      create_before_destroy = false
  }
}

data "aws_availability_zones" "all" {}

resource "aws_autoscaling_group" "example" {
    launch_configuration = aws_launch_configuration.hoge.id

    availability_zones = data.aws_availability_zones.all.names

    load_balancers = ["${aws_elb.example.name}"]
    health_check_type = "ELB"

    min_size = 2
    max_size = 5

    tag {
        key = "Name"
        value = "terraform autoscaling ver_6"
        propagate_at_launch = true
    }
}

resource "aws_security_group" "elb" {
    name = "terraform-example-elb"

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_elb" "example" {
    name = "terraform-asg-example"
    availability_zones = data.aws_availability_zones.all.names
    security_groups = [aws_security_group.elb.id]

    listener {
        lb_port = 80
        lb_protocol = "http"
        instance_port = 80
        instance_protocol = "http"
    }

    # 追加
    health_check {
        healthy_threshold = 2
        unhealthy_threshold = 2
        timeout = 3
        interval = 30
        target = "HTTP:80/"
    }
}

/*
data "aws_autoscaling_group" "foo" {
  name = "foo"
}
*/

/*
resource "aws_launch_template" "default" {
  count = "1"

  name_prefix = "default"
  image_id    = "${local.ami_id}"
  # instance_type = "t2.micro"

  key_name    = "${data.terraform_remote_state.common.aws_key_pair_admin_key_name}"

  vpc_security_group_ids = ["${aws_security_group.base_ssh.id}", "${aws_security_group.web_private.id}"]

  iam_instance_profile {
    name = "${data.terraform_remote_state.common.aws_iam_instance_profile_instance_profile_id}"
  }

  monitoring {
    enabled = true
  }

  lifecycle {
    create_before_destroy = true
  }
}
*/
