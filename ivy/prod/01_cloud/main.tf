variable "name" {
  type    = "string"
  default = "prod-ivy"
}

# vpc
resource "aws_vpc" "this" {
  cidr_block           = "20.10.0.0/16"

  # DNSサーバによる名前解決を有効
  enable_dns_support   = true

  # VPC内のリソースにパブリックDNSホスト名を自動的に割り当てる
  enable_dns_hostnames = true

  tags = {
    Name = var.name
  }
}

# igw
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = var.name
  }
}

# route table : 経路情報の格納
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.name}-public"
  }
}

# route
resource "aws_route" "this" {
  route_table_id         = aws_route_table.public.id
  gateway_id             = aws_internet_gateway.this.id
  destination_cidr_block = "0.0.0.0/0"
}

# public subnets
resource "aws_subnet" "az1" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "20.10.1.0/24"

  # このサブネットで起動したインスタンスにパブリックIPアドレスを自動的に割り当て
  map_public_ip_on_launch = true
  availability_zone       = "ap-northeast-1a"

  tags = {
    Name = "${var.name}-1a"
  }
}

resource "aws_route_table_association" "az1" {
  subnet_id      = aws_subnet.az1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_subnet" "az2" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "20.10.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-northeast-1c"
  tags = {
    Name = "${var.name}-1c"
  }
}

resource "aws_route_table_association" "az2" {
  subnet_id      = aws_subnet.az2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_subnet" "az3" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "20.10.3.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-northeast-1d"
  tags = {
    Name = "${var.name}-1d"
  }
}

resource "aws_route_table_association" "az3" {
  subnet_id      = aws_subnet.az3.id
  route_table_id = aws_route_table.public.id
}

# private subnets
resource "aws_subnet" "private_az1" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "20.10.64.0/24"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = false
  tags = {
    Name = "${var.name}-private_1a"
  }
}

resource "aws_subnet" "private_az2" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "20.10.65.0/24"
  availability_zone       = "ap-northeast-1c"
  map_public_ip_on_launch = false
  tags = {
    Name = "${var.name}-private_1c"
  }
}

resource "aws_subnet" "private_az3" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "20.10.66.0/24"
  availability_zone       = "ap-northeast-1d"
  map_public_ip_on_launch = false
  tags = {
    Name = "${var.name}-private_1d"
  }
}

# Elastic IP
resource "aws_eip" "nat_gateway_0" {
  vpc        = true
  depends_on = [aws_internet_gateway.this]
  tags = {
    Name = "${var.name}-natgw-1a"
  }
}

resource "aws_eip" "nat_gateway_1" {
  vpc        = true
  depends_on = [aws_internet_gateway.this]
  tags = {
    Name = "${var.name}-natgw-1c"
  }
}

resource "aws_eip" "nat_gateway_2" {
  vpc        = true
  depends_on = [aws_internet_gateway.this]
  tags = {
    Name = "${var.name}-natgw-1d"
  }
}

# NAT Gateway
resource "aws_nat_gateway" "nat_gateway_0" {
  allocation_id = aws_eip.nat_gateway_0.id
  subnet_id     = aws_subnet.az1.id
  depends_on    = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "nat_gateway_1" {
  allocation_id = aws_eip.nat_gateway_1.id
  subnet_id     = aws_subnet.az2.id
  depends_on    = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "nat_gateway_2" {
  allocation_id = aws_eip.nat_gateway_2.id
  subnet_id     = aws_subnet.az3.id
  depends_on    = [aws_internet_gateway.this]
}

resource "aws_route_table" "private_0" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.name}-private-1a"
  }
}

resource "aws_route_table" "private_1" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.name}-private-1c"
  }
}

resource "aws_route_table" "private_2" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.name}-private-1d"
  }
}

resource "aws_route" "private_0" {
  route_table_id         = aws_route_table.private_0.id
  nat_gateway_id         = aws_nat_gateway.nat_gateway_0.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "private_1" {
  route_table_id         = aws_route_table.private_1.id
  nat_gateway_id         = aws_nat_gateway.nat_gateway_1.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "private_2" {
  route_table_id         = aws_route_table.private_2.id
  nat_gateway_id         = aws_nat_gateway.nat_gateway_2.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "private_0" {
  subnet_id      = aws_subnet.private_az1.id
  route_table_id = aws_route_table.private_0.id
}

resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_az2.id
  route_table_id = aws_route_table.private_1.id
}

resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_az3.id
  route_table_id = aws_route_table.private_2.id
}

/*
output "vpc_id" {
 value = aws_vpc.this.id
}

output "subnet_public_az1_id" {
 value = aws_subnet.az1.id
}

output "subnet_public_az2_id" {
 value = aws_subnet.az2.id
}

output "subnet_public_az3_id" {
 value = aws_subnet.az3.id
}

output "subnet_private_az1_id" {
 value = aws_subnet.private_az1.id
}

output "subnet_private_az2_id" {
 value = aws_subnet.private_az2.id
}

output "subnet_private_az3_id" {
 value = aws_subnet.private_az3.id
}
*/
