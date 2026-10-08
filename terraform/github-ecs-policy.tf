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

# Lets CI run `terraform plan/apply` for the resources in this config.
# Deliberately has no iam:Put*/Attach* on SentinelCI-GitHubActions: CI must not
# be able to edit its own permissions. Changes to the policies in this file are
# applied locally.
resource "aws_iam_role_policy" "github_terraform_apply" {
  name = "SentinelCI-GitHubActions-TerraformApply"
  role = "SentinelCI-GitHubActions"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "Network"
        Effect = "Allow"
        Action = [
          "ec2:AssociateRouteTable",
          "ec2:AttachInternetGateway",
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:CreateInternetGateway",
          "ec2:CreateRoute",
          "ec2:CreateRouteTable",
          "ec2:CreateSecurityGroup",
          "ec2:CreateSubnet",
          "ec2:CreateTags",
          "ec2:CreateVpc",
          "ec2:DeleteInternetGateway",
          "ec2:DeleteRoute",
          "ec2:DeleteRouteTable",
          "ec2:DeleteSecurityGroup",
          "ec2:DeleteSubnet",
          "ec2:DeleteTags",
          "ec2:DeleteVpc",
          "ec2:Describe*",
          "ec2:DetachInternetGateway",
          "ec2:DisassociateRouteTable",
          "ec2:ModifySubnetAttribute",
          "ec2:ModifyVpcAttribute",
          "ec2:ReplaceRoute",
          "ec2:RevokeSecurityGroupEgress",
          "ec2:RevokeSecurityGroupIngress"
        ]
        Resource = "*"
        Condition = {
          StringEquals = { "aws:RequestedRegion" = "ap-south-1" }
        }
      },
      {
        Sid    = "ECS"
        Effect = "Allow"
        Action = [
          "ecs:CreateCluster",
          "ecs:CreateService",
          "ecs:DeleteCluster",
          "ecs:DeleteService",
          "ecs:DescribeClusters",
          "ecs:DescribeServices",
          "ecs:ListTagsForResource",
          "ecs:PutClusterCapacityProviders",
          "ecs:TagResource",
          "ecs:UntagResource",
          "ecs:UpdateCluster",
          "ecs:UpdateClusterSettings",
          "ecs:UpdateService"
        ]
        Resource = [
          "arn:aws:ecs:ap-south-1:660741725500:cluster/sentinel-ci",
          "arn:aws:ecs:ap-south-1:660741725500:service/sentinel-ci/sentinel-ci"
        ]
      },
      {
        # These ECS actions do not support resource-level permissions.
        Sid    = "ECSTaskDefinitions"
        Effect = "Allow"
        Action = [
          "ecs:DeregisterTaskDefinition",
          "ecs:DescribeTaskDefinition",
          "ecs:ListTagsForResource",
          "ecs:RegisterTaskDefinition",
          "ecs:TagResource"
        ]
        Resource = "*"
      },
      {
        Sid    = "Logs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:DeleteLogGroup",
          "logs:ListTagsForResource",
          "logs:ListTagsLogGroup",
          "logs:PutRetentionPolicy",
          "logs:DeleteRetentionPolicy",
          "logs:TagResource",
          "logs:UntagResource"
        ]
        # Some log actions are authorized against the ARN without the ":*" suffix.
        Resource = [
          "arn:aws:logs:ap-south-1:660741725500:log-group:/ecs/sentinel-ci",
          "arn:aws:logs:ap-south-1:660741725500:log-group:/ecs/sentinel-ci:*"
        ]
      },
      {
        Sid      = "LogsDescribe"
        Effect   = "Allow"
        Action   = ["logs:DescribeLogGroups"]
        Resource = "*"
      },
      {
        Sid    = "ECRRepository"
        Effect = "Allow"
        Action = [
          "ecr:CreateRepository",
          "ecr:DeleteRepository",
          "ecr:DescribeRepositories",
          "ecr:GetLifecyclePolicy",
          "ecr:GetRepositoryPolicy",
          "ecr:ListTagsForResource",
          "ecr:PutImageScanningConfiguration",
          "ecr:PutImageTagMutability",
          "ecr:TagResource",
          "ecr:UntagResource"
        ]
        Resource = "arn:aws:ecr:ap-south-1:660741725500:repository/sentinel-ci"
      },
      {
        Sid    = "TaskExecutionRole"
        Effect = "Allow"
        Action = [
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:GetRole",
          "iam:ListAttachedRolePolicies",
          "iam:ListInstanceProfilesForRole",
          "iam:ListRolePolicies",
          "iam:ListRoleTags",
          "iam:TagRole",
          "iam:UntagRole",
          "iam:UpdateAssumeRolePolicy"
        ]
        Resource = "arn:aws:iam::660741725500:role/SentinelCI-ECS-TaskExecutionRole"
      },
      {
        Sid    = "TaskExecutionRolePolicyAttachment"
        Effect = "Allow"
        Action = [
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy"
        ]
        Resource = "arn:aws:iam::660741725500:role/SentinelCI-ECS-TaskExecutionRole"
        Condition = {
          ArnEquals = {
            "iam:PolicyARN" = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
          }
        }
      },
      {
        # Read-only, so plan can refresh the policies defined in this file.
        Sid    = "ReadOwnRole"
        Effect = "Allow"
        Action = [
          "iam:GetRolePolicy",
          "iam:ListRolePolicies"
        ]
        Resource = "arn:aws:iam::660741725500:role/SentinelCI-GitHubActions"
      }
    ]
  })
}
