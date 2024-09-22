provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "terraform-statefile-medusa"
    key    = "terraform/state"
    region = "us-east-1"
  }
}

# VPC Creation
resource "aws_vpc" "medusa_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "medusa-vpc"
  }
}

# Subnet Creation
resource "aws_subnet" "medusa_subnet" {
  vpc_id            = aws_vpc.medusa_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "medusa-subnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "medusa_ig" {
  vpc_id = aws_vpc.medusa_vpc.id
  tags = {
    Name = "medusa-ig"
  }
}

# Route Table
resource "aws_route_table" "medusa_route_table" {
  vpc_id = aws_vpc.medusa_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.medusa_ig.id
  }

  tags = {
    Name = "medusa-route-table"
  }
}

# Route Table Association
resource "aws_route_table_association" "medusa_route_table_association" {
  subnet_id      = aws_subnet.medusa_subnet.id
  route_table_id = aws_route_table.medusa_route_table.id
}

# Security Group for SSH and Medusa
resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh_and_medusa"
  description = "Allow SSH and Medusa HTTP access"
  vpc_id      = aws_vpc.medusa_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9000
    to_port     = 9000
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

# EC2 Instance Creation
resource "aws_instance" "medusa_ec2" {
  ami           = "ami-0e86e20dae9224db8"  # Ubuntu AMI
  instance_type = "t2.medium"
  key_name      = "medusagit"  # Your SSH Key
  subnet_id     = aws_subnet.medusa_subnet.id
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]

  tags = {
    Name = "Medusa-EC2"
  }
}

output "instance_ip" {
  description = "The public IP of the EC2 instance"
  value       = aws_instance.medusa_ec2.public_ip
}

