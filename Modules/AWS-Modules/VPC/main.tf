# Configure AWS provider
provider "aws" {
  region = "us-east-1"
}

# Create a VPC
# This is the main private network in AWS
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  # Enable DNS support inside the VPC
  enable_dns_support = true

  # Enable DNS hostnames for resources
  enable_dns_hostnames = true

  tags = {
    Name = "dev-vpc"
  }
}

# Create a public subnet
# Resources in this subnet can access the internet
# when they have a public IP and the route table has an IGW route
resource "aws_subnet" "public" {
  vpc_id = aws_vpc.main.id

  cidr_block = "10.0.1.0/24"

  # Automatically assign public IPs to resources launched here
  map_public_ip_on_launch = true

  availability_zone = "us-east-1a"

  tags = {
    Name = "public-subnet"
  }
}

# Create an Internet Gateway
# It provides internet connectivity for the VPC
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "dev-igw"
  }
}

# Create a Route Table
# This route sends internet-bound traffic to the Internet Gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"

    # Send internet traffic through the Internet Gateway
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

# Associate the public subnet with the public route table
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}
