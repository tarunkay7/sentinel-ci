resource "aws_ecr_repository" "sentinel_ci" {
  name                 = "sentinel-ci"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  force_delete = false
}