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
  task_role_arn      = aws_iam_role.ecs_task.arn

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
    },
    {
      name      = "otel-collector"
      image     = "public.ecr.aws/aws-observability/aws-otel-collector:latest"
      essential = false

      environment = [
        {
          name  = "AOT_CONFIG_CONTENT"
          value = file("${path.module}/../otel/otel-config.yaml")
        }
      ]

      portMappings = [
        {
          containerPort = 4318
          hostPort      = 4318
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"

        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.sentinel_ci.name
          "awslogs-region"        = "ap-south-1"
          "awslogs-stream-prefix" = "otel"
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

resource "aws_iam_role" "ecs_task" {
  name = "SentinelCI-ECSTaskRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_xray_write" {
  role       = aws_iam_role.ecs_task.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}