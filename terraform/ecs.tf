resource "aws_ecs_cluster" "sentinel_ci" {
  name = "sentinel-ci"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "sentinel-ci-cluster"
  }
}

resource "aws_cloudwatch_log_group" "sentinel_ci" {
  name              = "/ecs/sentinel-ci"
  retention_in_days = 7
}


resource "aws_ecs_task_definition" "sentinel_ci" {
  family                   = "sentinel-ci"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"

  cpu    = "256"
  memory = "512"

  execution_role_arn = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name      = "sentinel-ci"
      image     = "${aws_ecr_repository.sentinel_ci.repository_url}:${var.image_tag}"
      essential = true

      portMappings = [
        {
          containerPort = 5000
          hostPort      = 5000
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"

        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.sentinel_ci.name
          "awslogs-region"        = "ap-south-1"
          "awslogs-stream-prefix" = "sentinel-ci"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "sentinel_ci" {
  name            = "sentinel-ci"
  cluster         = aws_ecs_cluster.sentinel_ci.id
  task_definition = aws_ecs_task_definition.sentinel_ci.arn

  desired_count = 1
  launch_type   = "FARGATE"

  network_configuration {
    subnets = [
      aws_subnet.sentinel_ci_public.id
    ]

    security_groups = [
      aws_security_group.sentinel_ci.id
    ]

    assign_public_ip = true
  }
}