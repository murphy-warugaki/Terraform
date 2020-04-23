# vpc
resource "aws_vpc" "example" {
  cidr_block           = "10.11.0.0/16"

  # DNSサーバによる名前解決を有効
  enable_dns_support   = true

  # VPC内のリソースにパブリックDNSホスト名を自動的に割り当てる
  enable_dns_hostnames = true

  tags = {
    Name = "test-ivy_ver7"
  }
}

# igw
resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.example.id

  tags = {
    Name = "test-ivy_ver7"
  }
}

# route table
resource "aws_route_table" "example" {
  vpc_id = aws_vpc.example.id
  tags = {
    Name = "test-ivy_ver7"
  }
}

# route
resource "aws_route" "example" {
  route_table_id         = aws_route_table.example.id
  gateway_id             = aws_internet_gateway.example.id
  destination_cidr_block = "0.0.0.0/0"
}

# some subnet
resource "aws_subnet" "az1" {
  vpc_id                  = aws_vpc.example.id
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
  route_table_id = aws_route_table.example.id
}

resource "aws_subnet" "az2" {
  vpc_id                  = aws_vpc.example.id
  cidr_block              = "10.10.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-northeast-1c"
  tags = {
    Name = "test-ivy-1c"
  }
}

resource "aws_route_table_association" "az2" {
  subnet_id      = aws_subnet.az2.id
  route_table_id = aws_route_table.example.id
}

resource "aws_subnet" "az3" {
  vpc_id                  = aws_vpc.example.id
  cidr_block              = "10.10.3.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-northeast-1d"
  tags = {
    Name = "test-ivy-1d"
  }
}

resource "aws_route_table_association" "az3" {
  subnet_id      = aws_subnet.az3.id
  route_table_id = aws_route_table.example.id
}
