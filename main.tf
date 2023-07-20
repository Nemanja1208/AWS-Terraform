resource "aws_vpc" "nemo_vpc" {
  cidr_block           = "10.123.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "dev"
  }
}

resource "aws_subnet" "nemo_public_subnet" {
  vpc_id                  = aws_vpc.nemo_vpc.id
  cidr_block              = "10.123.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-north-1a"

  tags = {
    Name : "dev-public"
  }
}

resource "aws_internet_gateway" "nemo_internet_gateway" {
  vpc_id = aws_vpc.nemo_vpc.id

  tags = {
    Name = "dev-internet-gateway"
  }
}

resource "aws_route_table" "nemo_public_route_table" {
  vpc_id = aws_vpc.nemo_vpc.id

  tags = {
    Name = "dev-public-route-table"
  }
}

resource "aws_route" "default_route" {
  route_table_id = aws_route_table.nemo_public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.nemo_internet_gateway.id
}