resource "aws_security_group" "sentinel_ci" {
  name        = "sentinel-ci-sg"
  description = "Allow HTTP traffic to SentinelCI"
  vpc_id      = aws_vpc.sentinel_ci.id

  ingress {
    description = "Flask application"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sentinel-ci-sg"
  }
}