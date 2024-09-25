# Security Group
resource "aws_security_group" "medusa_sg" {
  name        = "medusa-sg"
  description = "Security group for Medusa ECS tasks"
  vpc_id      = aws_vpc.medusa_vpc.id

  ingress {
    description = "Allow inbound traffic on port 9000"
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

  tags = {
    Name = "medusa-sg"
  }
}
