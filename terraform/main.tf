provider "aws" {
  region = "us-east-1"
}

resource "aws_security_group" "allow_ssh_http" {
  name        = "allow_ssh_http"
  description = "Allow SSH and HTTP traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Adjust to limit SSH access if needed
  }

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
    cidr_blocks = ["0.0.0.0/0"] # Allow access to Medusa on port 9000
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "medusa" {
  ami           = "ami-0e86e20dae9224db8" # Ubuntu AMI in us-east-1
  instance_type = "t2.micro"
  key_name      = var.key_name            # Pass key pair for SSH access

  user_data = file("user_data.sh")

  tags = {
    Name = "MedusaInstance"
  }

  security_groups = [aws_security_group.allow_ssh_http.name]
}

output "instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.medusa.public_ip
}

