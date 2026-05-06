resource "aws_service_discovery_private_dns_namespace" "internal" {
  name        = "microservices.local"
  description = "Internal DNS for microservices"
  vpc         = aws_vpc.main_vpc.id
}

# DNS record for Inventory App
resource "aws_service_discovery_service" "inventory_app" {
  name = "inventory-app" # Resolves to inventory-app.microservices.local
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.internal.id
    dns_records {
      ttl  = 10
      type = "A"
    }
  }
}

resource "aws_service_discovery_service" "billing_app" {
  name = "billing-app"
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.internal.id
    dns_records { 
      ttl = 10 
      type = "A" 
    }
  }
}

resource "aws_service_discovery_service" "inventory_db" {
  name = "inventory-db"
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.internal.id
    dns_records { 
      ttl = 10 
      type = "A" 
    }
  }
}

resource "aws_service_discovery_service" "billing_db" {
  name = "billing-db"
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.internal.id
    dns_records { 
      ttl = 10 
      type = "A" 
    }
  }
}

resource "aws_service_discovery_service" "rabbitmq" {
  name = "rabbitmq"
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.internal.id
    dns_records { 
      ttl = 10 
      type = "A" 
    }
  }
}