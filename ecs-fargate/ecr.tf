# ECR Repository
resource "aws_ecr_repository" "medusa_repo" {
  name                 = "medusa-app"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }
}

