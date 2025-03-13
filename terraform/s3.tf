terraform {
  backend "s3" {
    bucket = var.s3_bucket_name
    key = var.s3_state_key
    region = var.aws_region
    dynamodb_table = var.dynamodb_table_name
    encrypt = true
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
  region  = var.aws_region
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

