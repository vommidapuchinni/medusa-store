# Outputs
output "ecr_repository_url" {
  value       = aws_ecr_repository.medusa_repo.repository_url
  description = "ECR Repository URL"
}

output "ecs_cluster_name" {
  value       = aws_ecs_cluster.medusa_cluster.name
  description = "ECS Cluster Name"
}

output "ecs_service_name" {
  value       = aws_ecs_service.medusa_service.name
  description = "ECS Service Name"
}
