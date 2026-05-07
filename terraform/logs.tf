resource "aws_cloudwatch_log_group" "microservices_logs" {
  for_each = toset([
    "api-gateway-app",
    "inventory-app",
    "billing-app",
    "inventory-db",
    "billing-db",
    "rabbitmq-server"
  ])

  name              = "/ecs/microservices/${each.key}"
  retention_in_days = 7
}