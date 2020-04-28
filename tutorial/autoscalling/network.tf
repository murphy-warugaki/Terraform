# vpc
resource "aws_vpc" "test-ivy" {
  cidr_block           = "10.10.0.0/16"

  # DNSサーバによる名前解決を有効
  enable_dns_support   = true

  # VPC内のリソースにパブリックDNSホスト名を自動的に割り当てる
  enable_dns_hostnames = true

  tags = {
    Name = "test-ivy"
  }
}

# igw
resource "aws_internet_gateway" "test-ivy" {
  vpc_id = aws_vpc.test-ivy.id

  tags = {
    Name = "test-ivy"
  }
}

# route table
resource "aws_route_table" "test-ivy" {
  vpc_id = aws_vpc.test-ivy.id
  tags = {
    Name = "test-ivy"
  }
}

# route
resource "aws_route" "test-ivy" {
  route_table_id         = aws_route_table.test-ivy.id
  gateway_id             = aws_internet_gateway.test-ivy.id
  destination_cidr_block = "0.0.0.0/0"
}

# some subnet
resource "aws_subnet" "az1" {
  vpc_id                  = aws_vpc.test-ivy.id
  cidr_block              = "10.10.1.0/24"

  # このサブネットで起動したインスタンスにパブリックIPアドレスを自動的に割り当て
  map_public_ip_on_launch = true

  availability_zone       = "ap-northeast-1a"

  tags = {
    Name = "test-ivy-1a"
  }
}

resource "aws_route_table_association" "az1" {
  subnet_id      = aws_subnet.az1.id
  route_table_id = aws_route_table.test-ivy.id
}

resource "aws_subnet" "az2" {
  vpc_id                  = aws_vpc.test-ivy.id
  cidr_block              = "10.10.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-northeast-1c"
  tags = {
    Name = "test-ivy-1c"
  }
}

resource "aws_route_table_association" "az2" {
  subnet_id      = aws_subnet.az2.id
  route_table_id = aws_route_table.test-ivy.id
}

resource "aws_subnet" "az3" {
  vpc_id                  = aws_vpc.test-ivy.id
  cidr_block              = "10.10.3.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-northeast-1d"
  tags = {
    Name = "test-ivy-1d"
  }
}

resource "aws_route_table_association" "az3" {
  subnet_id      = aws_subnet.az3.id
  route_table_id = aws_route_table.test-ivy.id
}

# security
module "http_sg" {
  source      = "./security_group"
  name        = "http-sg"
  vpc_id      = aws_vpc.test-ivy.id
  port        = 80
  cidr_blocks = ["0.0.0.0/0"]
}

module "https_sg" {
  source      = "./security_group"
  name        = "https-sg"
  vpc_id      = aws_vpc.test-ivy.id
  port        = 443
  cidr_blocks = ["0.0.0.0/0"]
}

module "http_redirect_sg" {
  source      = "./security_group"
  name        = "http-redirect-sg"
  vpc_id      = aws_vpc.test-ivy.id
  port        = 8080
  cidr_blocks = ["0.0.0.0/0"]
}
