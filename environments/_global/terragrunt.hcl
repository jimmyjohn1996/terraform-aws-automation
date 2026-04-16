# environments/_global/terragrunt.hcl
# Root Terragrunt configuration
# This manages S3 backend, DynamoDB locking, and shared settings

locals {
  # AWS region
  aws_region = "us-east-1"
  
  # AWS account ID
  aws_account_id = run_cmd("aws", "sts", "get-caller-identity", "--query", "Account", "--output", "text")
  
  # Parse environment from path
  env_match    = regex(".*/(?P<env>[^/]+)/terragrunt.hcl", get_terragrunt_dir())
  environment  = env_match.env
}

# Generate provider configuration
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  
  contents = <<-EOF
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
      region = "${local.aws_region}"
      
      default_tags {
        tags = {
          Environment = "${local.environment}"
          ManagedBy   = "Terraform"
          ManagedWith = "Terragrunt"
          CreatedAt   = timestamp()
        }
      }
    }
  EOF
}

# Configure remote state in S3 with DynamoDB locking
remote_state {
  backend = "s3"
  
  config = {
    # S3 bucket must exist beforehand or use terraform to create it
    bucket         = "terraform-state-${local.aws_account_id}-${local.aws_region}"
    key            = "${local.environment}/terraform.tfstate"
    region         = local.aws_region
    encrypt        = true
    dynamodb_table = "terraform-locks-${local.aws_region}"
  }
  
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

# Prevent accidental destruction in production
prevent_destroy = local.environment == "prod" ? true : false
