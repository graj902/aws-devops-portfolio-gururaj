resource "aws_ecr_repository" "main" {
  name = var.repository_name

  image_scanning_configuration {
    scan_on_push = true
  }

  image_tag_mutability = "MUTABLE"

  # We will not use force_delete in our final code for safety.
  # It should only be added temporarily for a manual destroy if needed.
}