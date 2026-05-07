output "alb_url" {
  description = "The public URL of the Application Load Balancer"
  value       = "https://${aws_lb.main_alb.dns_name}"
}