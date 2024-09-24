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

resource "aws_instance" "medusa_ec2" {
  ami           = "ami-0e86e20dae9224db8"
  instance_type = "t2.medium"
  key_name      = "medusagit"
  subnet_id     = "subnet-0475bcd89ab2559c4"
  vpc_security_group_ids = ["sg-021967c054585e706"]

  tags = {
    Name = "Medusa-EC2"
  }
}

output "instance_ip" {
  description = "The public IP of the EC2 instance"
  value       = aws_instance.medusa_ec2.public_ip
}

