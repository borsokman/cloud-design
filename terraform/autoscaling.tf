# 1. API Gateway Auto-Scaling Target (Min 1, Max 3)
resource "aws_appautoscaling_target" "api_gateway_target" {
  max_capacity       = 3
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.main_cluster.name}/${aws_ecs_service.api_gateway_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# 2. API Gateway CPU Policy (Target 60%)
resource "aws_appautoscaling_policy" "api_gateway_cpu_policy" {
  name               = "api-gateway-cpu-60"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.api_gateway_target.resource_id
  scalable_dimension = aws_appautoscaling_target.api_gateway_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.api_gateway_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 60.0
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}

# 3. Inventory App Auto-Scaling Target (Min 1, Max 3)
resource "aws_appautoscaling_target" "inventory_app_target" {
  max_capacity       = 3
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.main_cluster.name}/${aws_ecs_service.inventory_app_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# 4. Inventory App CPU Policy (Target 60%)
resource "aws_appautoscaling_policy" "inventory_app_cpu_policy" {
  name               = "inventory-app-cpu-60"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.inventory_app_target.resource_id
  scalable_dimension = aws_appautoscaling_target.inventory_app_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.inventory_app_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 60.0
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}