provider "aws" {
  region = "us-east-1" # Modify to your desired region
}

resource "aws_instance" "medusa_ec2" {
  ami           = "ami-0e86e20dae9224db8"  # Ubuntu AMI
  instance_type = "t2.micro"               # Instance type
  key_name      = "medusagit"           # Your key name

  # User data to install Node.js, Medusa, and other required tools
  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update -y
              sudo apt-get install -y build-essential curl

              # Install Node.js
              curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
              sudo apt-get install -y nodejs

              # Install PM2 to manage Medusa server
              sudo npm install -g pm2

              # Install Git
              sudo apt-get install -y git

              # Clone Medusa Store
              git clone https://github.com/vommidapuchinni/medusa-store.git /home/ubuntu/medusa-store

              # Install Medusa Backend
              cd /home/ubuntu/medusa-store
              npm install

              # Start Medusa Server
              pm2 start "npm run develop"
              EOF

  # Allow SSH access
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]

  tags = {
    Name = "Medusa-EC2"
  }
}

# Security group to allow SSH access and port 9000 for Medusa
resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh_and_medusa"
  description = "Allow SSH and Medusa HTTP access"

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

# Output the public IP of the instance
output "instance_ip" {
  description = "The public IP of the EC2 instance"
  value       = aws_instance.medusa_ec2.public_ip
}
