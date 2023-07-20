resource "aws_vpc" "nemo_vpc" {
  cidr_block = "10.123.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "dev"
  }
}

resource "aws_subnet" "nemo_public_subnet" {
  vpc_id = aws_vpc.nemo_vpc.id
  cidr_block = "10.123.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "eu-north-1a"

  tags = {
    Name: "dev-public"
  }
}