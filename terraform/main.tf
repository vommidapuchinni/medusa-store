provider "aws" {
  region = "us-east-1"
}

# Create a VPC
resource "aws_vpc" "medusa_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "MedusaVPC"
  }
}

# Create a subnet
resource "aws_subnet" "medusa_subnet" {
  vpc_id            = aws_vpc.medusa_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "MedusaSubnet"
  }
}

# Create a security group allowing HTTP and port 9000 traffic
resource "aws_security_group" "medusa_sg" {
  vpc_id = aws_vpc.medusa_vpc.id
  name   = "medusa_sg"

  ingress {
    from_port   = 80
    to_port     = 80
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

# EC2 instance for Medusa application
resource "aws_instance" "medusa_instance" {
  ami           = "ami-0e86e20dae9224db8"  # Ubuntu AMI
  instance_type = "t2.micro"
  key_name      = "medusagit"              # Key name
  subnet_id     = aws_subnet.medusa_subnet.id
  security_groups = [aws_security_group.medusa_sg.name]

  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update -y
              sudo apt-get install -y nodejs npm git

              # Clone the Medusa application from GitHub
              git clone -b master https://github.com/vommidapuchinni/medusa-store.git /home/ubuntu/medusa-app
              cd /home/ubuntu/medusa-app

              # Install dependencies
              npm install

              # Set up environment variables
              echo "DATABASE_URL=postgres://postgres:chinni@localhost:5432/medusa_db" >> .env
              echo "JWT_SECRET=something" >> .env
              echo "COOKIE_SECRET=something" >> .env

              # Start the Medusa server
              npm run start &
              EOF

  tags = {
    Name = "MedusaEC2Instance"
  }
}

# Output the EC2 instance's public IP
output "instance_ip" {
  value = aws_instance.medusa_instance.public_ip
}

