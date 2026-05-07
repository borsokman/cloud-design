resource "aws_ecr_repository" "repos" {
  for_each = toset([
    "api-gateway-app",
    "inventory-app",
    "billing-app",
    "rabbitmq-server",
    "inventory-db",
    "billing-db"
  ])
  
  name                 = each.key
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}

# These blocks dynamically fetch your Account ID and Region
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

output "ecr_registry_url" {
  value = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com"
}
