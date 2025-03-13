variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "s3_input_bucket_name" {
  description = "Name of the input bucket for PDFs"
  type        = string
  default     = "input-bucket-pinballtec"
}

variable "s3_output_bucket_name" {
  description = "Name of the input bucket for PDFs"
  type        = string
  default     = "output-bucket-pinballtec"
}

variable "s3_state_key" {
  description = "S3 key path for Terraform state file"
  type        = string
  default     = "terraform/state/default.tfstate"
}

variable "dynamodb_table_name" {
  description = "DynamoDB table for state locking"
  type        = string
  default     = "terraform-lock-table"
}

variable "vpc_cidr_block" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_a_cidr_block" {
  description = "CIDR block for subnet A"
  type        = string
  default     = "10.0.1.0/24"
}

variable "subnet_a_az" {
  description = "Availability zone for subnet A"
  type        = string
  default     = "eu-central-1a"
}

variable "subnet_b_cidr_block" {
  description = "CIDR block for subnet B"
  type        = string
  default     = "10.0.2.0/24"
}

variable "subnet_b_availability_zone" {
  description = "Availability zone for subnet B"
  type        = string
  default     = "eu-central-1b"
}

variable "subnet_ids" {
  description = "List of subnet IDs for ECS service"
  type        = list(string)
  default     = []
}

variable "vpc_id" {
  description = "VPC ID for security groups"
  type        = string
  default     = ""
}
