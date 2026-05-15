# 1. ALB Security Group (Internet -> ALB)
resource "aws_security_group" "alb_sg" {
  name        = "alb-security-group"
  description = "Allow HTTP traffic from the internet"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description = "HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

    ingress {
    description = "HTTPS from Internet"
    from_port   = 443
    to_port     = 443
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

# 2. API Gateway Security Group (ALB -> API Gateway)
resource "aws_security_group" "api_gateway_sg" {
  name        = "api-gateway-sg"
  description = "Allow traffic from ALB to API Gateway"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description     = "Traffic from ALB"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 3. Internal Services Security Group (API Gateway -> Apps -> DBs/RabbitMQ)
resource "aws_security_group" "internal_sg" {
  name        = "internal-services-sg"
  description = "Allow internal traffic between microservices"
  vpc_id      = aws_vpc.main_vpc.id

  # Allow Apps (8080)
  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.api_gateway_sg.id]
  }

  # Allow RabbitMQ (5672)
  ingress {
    from_port       = 5672
    to_port         = 5672
    protocol        = "tcp"
    self            = true # Allow resources in this SG to talk to each other
    security_groups = [aws_security_group.api_gateway_sg.id]
  }

  # Allow PostgreSQL (5432)
  ingress {
    from_port = 5432
    to_port   = 5432
    protocol  = "tcp"
    self      = true
  }

    # Allow EFS / NFS (2049) so databases can mount their hard drives
  ingress {
    from_port = 2049
    to_port   = 2049
    protocol  = "tcp"
    self      = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}