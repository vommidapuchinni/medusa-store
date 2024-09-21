provider "aws" {
  region = "us-east-1" # Modify to your desired region
}

# Backend configuration using the existing S3 bucket
terraform {
  backend "s3" {
    bucket = "terraform-statefile-medusa"  # Your existing bucket name
    key    = "terraform/state"               # Path within the bucket
    region = "us-east-1"                     # Your AWS region
  }
}

# Create a VPC
resource "aws_vpc" "medusa_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "medusa-vpc"
  }
}

# Create a subnet
resource "aws_subnet" "medusa_subnet" {
  vpc_id            = aws_vpc.medusa_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a" # Modify as needed
  map_public_ip_on_launch = true
  tags = {
    Name = "medusa-subnet"
  }
}

# Create an internet gateway
resource "aws_internet_gateway" "medusa_ig" {
  vpc_id = aws_vpc.medusa_vpc.id
  tags = {
    Name = "medusa-ig"
  }
}

# Create a route table
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

# Associate the route table with the subnet
resource "aws_route_table_association" "medusa_route_table_association" {
  subnet_id      = aws_subnet.medusa_subnet.id
  route_table_id = aws_route_table.medusa_route_table.id
}

# Security group to allow SSH access and port 9000 for Medusa
resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh_and_medusa"
  description = "Allow SSH and Medusa HTTP access"
  vpc_id     = aws_vpc.medusa_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow SSH from anywhere (consider restricting it)
  }

  ingress {
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow HTTP traffic to Medusa
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create the EC2 instance
resource "aws_instance" "medusa_ec2" {
  ami           = "ami-0e86e20dae9224db8"  # Ubuntu AMI
  instance_type = "t2.micro"               # Instance type
  key_name      = "medusagit"              # Your key name
  subnet_id     = aws_subnet.medusa_subnet.id

  # User data to set up the environment
  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update -y && sudo apt-get upgrade -y
              
              # Install Node.js and npm
              sudo apt install -y nodejs npm

              # Install PostgreSQL
              sudo apt install -y postgresql postgresql-contrib
              sudo systemctl start postgresql
              sudo systemctl enable postgresql

              # Create PostgreSQL user and database
              sudo -u postgres psql -c "CREATE USER medusa_user WITH PASSWORD 'chinni' CREATEDB;"
              sudo -u postgres psql -c "CREATE DATABASE medusa_db OWNER medusa_user;"
              sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE medusa_db TO medusa_user;"

              # Install Redis
              sudo apt install -y redis-server
              sudo systemctl enable redis-server
              sudo systemctl start redis-server

              # Clone the Medusa app repository if it doesn't exist
              if [ ! -d "./medusa-store" ]; then
                git clone https://github.com/vommidapuchinni/medusa-store.git ./medusa-store
              else
                cd ./medusa-store && git pull
              fi

              # Change directory to the cloned repo
              cd ./medusa-store

              # Install Medusa dependencies
              sudo npm install -g @medusajs/medusa-cli
              npm install

              # Run database migrations
              npx medusa migrations run

              # Start the Medusa application in the background
              nohup npm run start > medusa.log 2>&1 &

              echo "Medusa deployment initiated."
              EOF

  # Allow SSH access
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]

  tags = {
    Name = "Medusa-EC2"
  }
}

# Output the public IP of the instance
output "instance_ip" {
  description = "The public IP of the EC2 instance"
  value       = aws_instance.medusa_ec2.public_ip
}
