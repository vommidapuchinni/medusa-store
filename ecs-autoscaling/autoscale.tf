# ECS Autoscaling Target
resource "aws_appautoscaling_target" "ecs_scaling_target" {
  max_capacity       = 3  # Maximum number of tasks
  min_capacity       = 1  # Minimum number of tasks
  resource_id        = "service/${aws_ecs_cluster.medusa_cluster.name}/${aws_ecs_service.medusa_service.name}"  # Resource ID for the service
  scalable_dimension = "ecs:service:DesiredCount"  # Dimension for scaling
  service_namespace  = "ecs"  # Service namespace
}

# CloudWatch Alarm for High CPU Utilization
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "High CPU Alarm"
  comparison_operator  = "GreaterThanThreshold"  # Trigger if CPU > threshold
  evaluation_periods   = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60  # Evaluation period in seconds
  statistic           = "Average"  # Use average CPU utilization
  threshold           = 75  # Trigger alarm if CPU > 75%

  dimensions = {
    ClusterName = aws_ecs_cluster.medusa_cluster.name
    ServiceName = aws_ecs_service.medusa_service.name
  }

  alarm_actions = [aws_appautoscaling_policy.scale_up.arn]  # Action to take on alarm
}

# CloudWatch Alarm for Low CPU Utilization
resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name          = "Low CPU Alarm"
  comparison_operator  = "LessThanThreshold"  # Trigger if CPU < threshold
  evaluation_periods   = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60  # Evaluation period in seconds
  statistic           = "Average"  # Use average CPU utilization
  threshold           = 30  # Trigger alarm if CPU < 30%

  dimensions = {
    ClusterName = aws_ecs_cluster.medusa_cluster.name
    ServiceName = aws_ecs_service.medusa_service.name
  }

  alarm_actions = [aws_appautoscaling_policy.scale_down.arn]  # Action to take on alarm
}

# Autoscaling Policy for Scaling Up
resource "aws_appautoscaling_policy" "scale_up" {
  name                   = "scale-up"
  policy_type           = "TargetTrackingScaling"  # Policy type
  resource_id           = aws_appautoscaling_target.ecs_scaling_target.id  # Reference the scaling target
  scalable_dimension     = aws_appautoscaling_target.ecs_scaling_target.scalable_dimension
  service_namespace      = aws_appautoscaling_target.ecs_scaling_target.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = 75.0  # Target CPU utilization
    scale_out_cooldown = 60  # Cooldown period after scaling out
    scale_in_cooldown  = 60  # Cooldown period after scaling in

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"  # Predefined metric type
    }
  }
}

# Autoscaling Policy for Scaling Down
resource "aws_appautoscaling_policy" "scale_down" {
  name                   = "scale-down"
  policy_type           = "TargetTrackingScaling"  # Policy type
  resource_id           = aws_appautoscaling_target.ecs_scaling_target.id  # Reference the scaling target
  scalable_dimension     = aws_appautoscaling_target.ecs_scaling_target.scalable_dimension
  service_namespace      = aws_appautoscaling_target.ecs_scaling_target.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = 30.0  # Target CPU utilization
    scale_out_cooldown = 60  # Cooldown period after scaling out
    scale_in_cooldown  = 60  # Cooldown period after scaling in

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"  # Predefined metric type
    }
  }
