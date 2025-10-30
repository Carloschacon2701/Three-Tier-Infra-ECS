resource "aws_amplify_app" "this" {
  count        = var.create_amplify_app ? 1 : 0
  name         = "${var.project_name}-amplify"
  repository   = var.amplify_app_repository.repository
  access_token = var.amplify_app_repository.token

  build_spec = <<-EOT
   version: 0.1
    frontend:
      phases:
        preBuild:
          commands:
            - yarn install
        build:
          commands:
            - yarn run build
      artifacts:
        baseDirectory: build
        files:
          - '**/*'
      cache:
        paths:
          - node_modules/**/*
  EOT

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Project = var.project_name
  }
}

resource "aws_amplify_branch" "this" {
  count                       = var.create_amplify_app ? 1 : 0
  app_id                      = aws_amplify_app.this[0].id
  branch_name                 = var.amplify_app_repository.branch
  description                 = "${var.project_name} ${var.amplify_app_repository.branch} branch"
  enable_basic_auth           = false
  enable_pull_request_preview = false

  depends_on = [aws_amplify_app.this[0]]
}
