variable "s3_input_bucket_name" {
  description = "S3 bucket name for Terraform state"
  type        = string
  default     = "terraform-state-bucket-techniproject"
}

variable "s3_state_key" {
  description = "S3 key path for Terraform state file"
  type        = string
  default     = "terraform/state/default.tfstate"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "dynamodb_table_name" {
  description = "DynamoDB table for state locking"
  type        = string
  default     = "terraform-lock-table"
}

variable "input_bucket_name" {
  type        = string
  description = "Name of the input bucket for PDFs"
  default = "input-"
}
