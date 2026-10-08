resource "aws_iam_role_policy" "github_ecs_deploy" {
  name = "SentinelCI-GitHubActions-ECSDeploy"
  role = "SentinelCI-GitHubActions"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "ECSDeployment"
        Effect = "Allow"

        Action = [
          "ecs:DescribeServices",
          "ecs:DescribeTaskDefinition",
          "ecs:DescribeTasks",
          "ecs:ListTasks",
          "ecs:RegisterTaskDefinition",
          "ecs:UpdateService"
        ]

        Resource = "*"
      },
      {
        Sid    = "PassECSTaskExecutionRole"
        Effect = "Allow"

        Action = [
          "iam:PassRole"
        ]

        Resource = aws_iam_role.ecs_task_execution.arn
      }
    ]
  })
}

resource "aws_iam_role_policy" "github_terraform_state" {
  name = "SentinelCI-GitHubActions-TerraformState"
  role = "SentinelCI-GitHubActions"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "TerraformStateBucket"
        Effect = "Allow"

        Action = [
          "s3:ListBucket"
        ]

        Resource = "arn:aws:s3:::sentinel-ci-terraform-state-660741725500"
      },

      {
        Sid    = "TerraformStateObjects"
        Effect = "Allow"

        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]

        Resource = "arn:aws:s3:::sentinel-ci-terraform-state-660741725500/sentinel-ci/*"
      }
    ]
  })
}