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

resource "aws_ecr_repository" "ec2_client_repo" {
  name = "send-ocr-request-repo"
}

output "ec2_client_ecr_url" {
  value = aws_ecr_repository.ec2_client_repo.repository_url
}

resource "aws_s3_bucket" "input_bucket" {
  bucket = var.s3_input_bucket_name
}

resource "aws_s3_bucket" "output_bucket" {
  bucket = var.s3_output_bucket_name
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


resource "aws_iam_role" "ec2_iam_role" {
  name = "ec2_ocr_sender_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}


# acess policy for ec2 role 
resource "aws_iam_role_policy" "ec2_policy" {
  name = "ec2_ocr_policy"
  role = aws_iam_role.ec2_instance_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["sqs:*", "logs:*", "s3:*", "ecr:*"]
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

# Security Group for ECS
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

# EC2 instance (for SQS alerting)
resource "aws_instance" "ocr_client" {
  ami                    = "ami-0aef57767f5404a99" # Amazon Linux 2 
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_subnet_a.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  user_data = <<-EOF
    #!/bin/bash
    sudo apt update -y
    sudo apt install docker.io -y
    sudo systemctl start docker
    sudo usermod -aG docker ubuntu
  EOF

  tags = {
    Name = "OCR-EC2-Client"
  }
}

# Security Group for EC2
resource "aws_security_group" "ec2_sg" {
  name   = "ec2-client-sg"
  vpc_id = aws_vpc.ocr_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # можно ограничить твоим IP
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# IAM role for EC2 ()
resource "aws_iam_role" "ec2_role" {
  name = "ec2_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "ec2_policy" {
  name = "ec2_sqs_policy"
  role = aws_iam_role.ec2_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["sqs:*", "logs:*", "s3:*"],
      Resource = "*"
    }]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2_profile"
  role = aws_iam_role.ec2_role.name
}

# Security Group for EC2 (SSH)
resource "aws_security_group" "ec2_sg" {
  name   = "ec2-sg"
  vpc_id = aws_vpc.ocr_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["188.146.34.60"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["188.146.34.60"]
  }
}

# Klucz ( SSH )
resource "aws_key_pair" "ec2_key" {
  key_name   = "ocr-ec2-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

# AMI :
data "aws_ami" "ubuntu_latest" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# EC2 with  AMI
resource "aws_instance" "ocr_client" {
  ami                    = data.aws_ami.ubuntu_latest.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_subnet_a.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  key_name               = aws_key_pair.ocr_ec2_key.key_name

  user_data = <<-EOF
    #!/bin/bash
    sudo apt update -y
    sudo apt install -y docker.io
    sudo usermod -aG docker ubuntu
    sudo systemctl enable docker

    aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${aws_ecr_repository.ec2_client_repo.repository_url}


    docker run -d \
      -e AWS_REGION=${var.aws_region} \
      -e SQS_QUEUE_URL=${aws_sqs_queue.ocr_queue.id} \
      ${aws_ecr_repository.ec2_client_repo.repository_url}:latest
  EOF

  tags = {
    Name = "OCRClientEC2"
  }
}
