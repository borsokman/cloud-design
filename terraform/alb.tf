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

# 3. The Listener Redirect HTTP (80) to HTTPS (443)
resource "aws_lb_listener" "http_redirect" {
  load_balancer_arn = aws_lb.main_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# HTTPS Listener (443) attached to ACM Certificate
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.imported_cert.arn

  default_action {
    type = "authenticate-cognito"
    authenticate_cognito {
      user_pool_arn       = aws_cognito_user_pool.pool.arn
      user_pool_client_id = aws_cognito_user_pool_client.client.id
      user_pool_domain    = aws_cognito_user_pool_domain.main.domain
    }
  }

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api_gateway_tg.arn
  }
}