# 1. Create the Private DNS Namespace
resource "aws_service_discovery_private_dns_namespace" "microservices" {
  name        = "backend.local"
  description = "Internal DNS for microservices"
  vpc         = aws_vpc.main_vpc.id
}

# 2. Create the DNS records for each service
resource "aws_service_discovery_service" "sd_services" {
  for_each = toset([
    "inventory-app",
    "billing-app",
    "inventory-db",
    "billing-db",
    "rabbitmq"
  ])

  name = each.key

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.microservices.id
    dns_records {
      ttl  = 60
      type = "A"
    }
    routing_policy = "MULTIVALUE"
  }
  
  health_check_custom_config {
    failure_threshold = 1
  }
}