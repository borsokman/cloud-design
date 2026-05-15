resource "aws_ecs_task_definition" "api_gateway" {
  family                   = "api-gateway-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

    runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }
  
  container_definitions = jsonencode([
    {
      name      = "api-gateway-app"
      image     = "327425719370.dkr.ecr.eu-north-1.amazonaws.com/api-gateway-app:v1"
      essential = true
      portMappings = [{ containerPort = 3000, protocol = "tcp" }]
            logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/microservices/api-gateway-app"
          "awslogs-region"        = "eu-north-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
      environment = [
        { name = "INVENTORY_URL", value = "http://inventory-app.backend.local:8080" },
        { name = "RABBITMQ_HOST", value = "rabbitmq.backend.local" },
        { name = "RABBITMQ_PORT", value = "5672" },
        { name = "RABBITMQ_USER", value = "billing_user" }
      ]
      secrets = [
        { name = "RABBITMQ_PASSWORD", valueFrom = aws_ssm_parameter.rabbitmq_password.arn }
      ]
    }
  ])
}

resource "aws_ecs_task_definition" "inventory_app" {
  family                   = "inventory-app-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

    runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }
  
  container_definitions = jsonencode([
    {
      name      = "inventory-app"
      image     = "327425719370.dkr.ecr.eu-north-1.amazonaws.com/inventory-app:v1"
      essential = true
      portMappings = [{ containerPort = 8080, protocol = "tcp" }]
            logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/microservices/inventory-app"
          "awslogs-region"        = "eu-north-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
      environment = [
        { name = "DB_HOST", value = "inventory-db.backend.local" },
        { name = "DB_PORT", value = "5432" },
        { name = "DB_NAME", value = "movies_db" },
        { name = "DB_USER", value = "movies_user" }
      ]
      secrets = [
        { name = "DB_PASSWORD", valueFrom = aws_ssm_parameter.inventory_db_password.arn }
      ]
    }
  ])
}

resource "aws_ecs_task_definition" "billing_app" {
  family                   = "billing-app-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

    runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }
  
  container_definitions = jsonencode([
    {
      name      = "billing-app"
      image     = "327425719370.dkr.ecr.eu-north-1.amazonaws.com/billing-app:v1"
      essential = true
      portMappings = [{ containerPort = 8080, protocol = "tcp" }]
            logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/microservices/billing-app"
          "awslogs-region"        = "eu-north-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
      environment = [
        { name = "PYTHONUNBUFFERED", value = "1" },
        { name = "DB_HOST", value = "billing-db.backend.local" },
        { name = "DB_PORT", value = "5432" },
        { name = "DB_NAME", value = "billing_db" },
        { name = "DB_USER", value = "orders_user" },
        { name = "RABBITMQ_HOST", value = "rabbitmq.backend.local" },
        { name = "RABBITMQ_PORT", value = "5672" },
        { name = "RABBITMQ_USER", value = "billing_user" }
      ]
      secrets = [
        { name = "DB_PASSWORD", valueFrom = aws_ssm_parameter.billing_db_password.arn },
        { name = "RABBITMQ_PASSWORD", valueFrom = aws_ssm_parameter.rabbitmq_password.arn }
      ]
    }
  ])
}

resource "aws_ecs_task_definition" "rabbitmq" {
  family                   = "rabbitmq-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }
  
  container_definitions = jsonencode([
    {
      name      = "rabbitmq-server"
      image     = "rabbitmq:3-management"
      essential = true
      portMappings = [
        { containerPort = 5672, protocol = "tcp" },
        { containerPort = 15672, protocol = "tcp" }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/microservices/rabbitmq-server"
          "awslogs-region"        = "eu-north-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
      environment = [
        { name = "RABBITMQ_DEFAULT_USER", value = "billing_user" }
      ]
      secrets = [
        { name = "RABBITMQ_DEFAULT_PASS", valueFrom = aws_ssm_parameter.rabbitmq_password.arn }
      ]
    }
  ])
}

resource "aws_ecs_task_definition" "inventory_db" {
  family                   = "inventory-db-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }

  container_definitions = jsonencode([
    {
      name      = "inventory-db"
      image     = "327425719370.dkr.ecr.eu-north-1.amazonaws.com/inventory-db:v1"
      essential = true
      portMappings = [{ containerPort = 5432, protocol = "tcp" }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/microservices/inventory-db"
          "awslogs-region"        = "eu-north-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
      environment = [
        { name = "DB_NAME", value = "movies_db" },
        { name = "DB_USER", value = "movies_user" }
      ]
      secrets = [
        { name = "DB_PASSWORD", valueFrom = aws_ssm_parameter.inventory_db_password.arn }
      ]
    }
  ])
}

resource "aws_ecs_task_definition" "billing_db" {
  family                   = "billing-db-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }

  container_definitions = jsonencode([
    {
      name      = "billing-db"
      image     = "327425719370.dkr.ecr.eu-north-1.amazonaws.com/billing-db:v1"
      essential = true
      portMappings = [{ containerPort = 5432, protocol = "tcp" }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/microservices/billing-db"
          "awslogs-region"        = "eu-north-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
      environment = [
        { name = "DB_NAME", value = "billing_db" },
        { name = "DB_USER", value = "orders_user" }
      ]
      secrets = [
        { name = "DB_PASSWORD", valueFrom = aws_ssm_parameter.billing_db_password.arn }
      ]
    }
  ])
}