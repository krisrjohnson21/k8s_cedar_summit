resource "aws_ecr_repository" "cedar_summit" {
  name                 = "cedar-summit"
  image_tag_mutability = "MUTABLE"
  force_delete         = true # Easy cleanup for a dev project

  image_scanning_configuration {
    scan_on_push = true
  }
}
