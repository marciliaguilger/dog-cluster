provider "aws" {
  region = "us-east-1" 
}

# Criar a VPC
resource "aws_vpc" "dog-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "dog-vpc"
  }
}

# Criar a Subnet Pública 1
resource "aws_subnet" "public_subnet_1" {
  vpc_id            = aws_vpc.dog-vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"  
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-1"
  }
}

# Criar a Subnet Pública 2
resource "aws_subnet" "public_subnet_2" {
  vpc_id            = aws_vpc.dog-vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"  
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-2"
  }
}

# Criar a Subnet Privada 1
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.dog-vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"  
  tags = {
    Name = "private-subnet-1"
  }
}

# Criar a Subnet Privada 2
resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.dog-vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b"  
  tags = {
    Name = "private-subnet-2"
  }
}

# Criar o Internet Gateway
resource "aws_internet_gateway" "dog-gateway" {
  vpc_id = aws_vpc.dog-vpc.id
  tags = {
    Name = "dog-gateway"
  }
}

# Criar a Tabela de Roteamento Pública
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.dog-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dog-gateway.id
  }
  tags = {
    Name = "public-route-table"
  }
}

# Associar Subnets Públicas à Tabela de Roteamento Pública
resource "aws_route_table_association" "public_subnet_1_association" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_subnet_2_association" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_route_table.id
}