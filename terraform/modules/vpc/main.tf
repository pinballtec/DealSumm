variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}


variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "subnet_a_cidr_block" {
  description = "CIDR block for Subnet A"
  type        = string
}

variable "subnet_a_az" {
  description = "Availability Zone for Subnet A"
  type        = string
}

variable "subnet_b_cidr_block" {
  description = "CIDR block for Subnet B"
  type        = string
}

variable "subnet_b_availability_zone" {
  description = "Availability Zone for Subnet B"
  type        = string
}


resource "aws_vpc" "ocr_vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = "OCR-VPC"
  }
}

# subnet A
resource "aws_subnet" "public_subnet_a" {
  vpc_id            = aws_vpc.ocr_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = var.subnet_a_az

  tags = {
    Name = "OCR-Subnet-A"
  }
}

# subnet B
resource "aws_subnet" "public_subnet_b" {
  vpc_id            = aws_vpc.ocr_vpc.id
  cidr_block        = var.subnet_b_cidr_block
  availability_zone = "${var.aws_region}b"
  tags = {
    Name = "OCR-Subnet-B"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.ocr_vpc.id
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.ocr_vpc.id
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

resource "aws_route_table_association" "public_a_assoc" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_b_assoc" {
  subnet_id      = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.public_rt.id
}


output "vpc_id" {
  value = aws_vpc.ocr_vpc.id
}

output "subnet_ids" {
  value = [aws_subnet.public_subnet_a.id, aws_subnet.public_subnet_b.id]
}
