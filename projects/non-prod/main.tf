terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source = "../../modules/vpc"

  name                 = "${var.environment}-vpc"
  cidr_block          = var.vpc_cidr
  public_subnet_cidrs = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones  = var.availability_zones
  tags                = local.common_tags
}

module "s3_bucket" {
  source = "../../modules/s3"

  bucket_name        = "${var.environment}-${var.project_name}-bucket"
  versioning_enabled = false
  tags               = local.common_tags
}

module "lambda_role" {
  source = "../../modules/iam"

  role_name = "${var.environment}-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
  policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  ]
  tags = local.common_tags
}

module "dynamodb_table" {
  source = "../../modules/dynamodb"

  table_name   = "${var.environment}-${var.project_name}-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"
  attributes = [
    {
      name = "id"
      type = "S"
    }
  ]
  tags = local.common_tags
}