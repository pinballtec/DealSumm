terraform {
  backend "s3" {
    bucket         = var.s3_bucket_name
    key            = var.s3_state_key
    region         = var.aws_region
    dynamodb_table = var.dynamodb_table_name
    encrypt        = true
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  required_version = ">= 1.3.0"
}

provider "aws" {
  region = var.aws_region
}


resource "aws_s3_bucket" "input_bucket" {
  bucket = var.s3_input_bucket_name
}

resource "aws_s3_bucket_versioning" "input_bucket_versioning" {
  bucket = var.s3_input_bucket_name
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_sqs_queue" "ocr_queue" {
  name = "OCRQueue"
}

resource "aws_ecs_cluster" "ocr_cluster" {
  name = "OCRCluster"
}

# IAM Role for ECS Task Execution
resource "aws_iam_role" "ecs_task_exec_role" {
  name = "ecs_task_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}


# IAM Policy (for SQS and CloudWatch Logs)
resource "aws_iam_role_policy" "ecs_task_policy" {
  name = "ecs_task_policy"
  role = aws_iam_role.ecs_task_exec_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow",
      Action   = ["sqs:*", "logs:*"],
      Resource = "*"
    }]
  })
}


# ECS Task Definition (with OCRMyPDF)
resource "aws_ecs_task_definition" "ocr_task" {
  family                   = "ocrmypdf-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = aws_iam_role.ecs_task_exec_role.arn

  container_definitions = jsonencode([{
    name       = "ocrmypdf-container"
    image      = "ocrmypdf/ocrmypdf" # image from DockerHub
    essential  = true
    entryPoint = ["sh", "-c"]
    command    = ["your-command-to-read-from-sqs-and-process-pdfs.sh"]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/ocrmypdf"
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
}

# ECS Service
resource "aws_ecs_service" "ocr_service" {
  name            = "ocrmypdf-service"
  cluster         = aws_ecs_cluster.ocr_cluster.id
  task_definition = aws_ecs_task_definition.ocr_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.subnet_ids
    security_groups = [aws_security_group.ocr_sg.id]
  }
}

# Security Group для ECS
resource "aws_security_group" "ocr_sg" {
  name   = "ocr-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
