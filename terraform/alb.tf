# 1. The Application Load Balancer
resource "aws_lb" "main_alb" {
  name               = "microservices-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]
}

# 2. The Target Group (Points to the API Gateway)
resource "aws_lb_target_group" "api_gateway_tg" {
  name        = "api-gateway-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main_vpc.id
  target_type = "ip" # Required for Fargate

  health_check {
    path                = "/"
    matcher             = "200-499" # Accepts 404 if no root route is defined
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# 3. The Listener (Listens on port 80 and forwards to the Target Group)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api_gateway_tg.arn
  }
}