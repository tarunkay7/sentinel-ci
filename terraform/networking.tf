resource "aws_vpc" "sentinel_ci" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "sentinel-ci-vpc"
  }
}

resource "aws_subnet" "sentinel_ci_public" {
  vpc_id                  = aws_vpc.sentinel_ci.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "sentinel-ci-public-subnet"
  }
}

resource "aws_internet_gateway" "sentinel_ci" {
  vpc_id = aws_vpc.sentinel_ci.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.sentinel_ci.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.sentinel_ci.id
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.sentinel_ci_public.id
  route_table_id = aws_route_table.public.id
}