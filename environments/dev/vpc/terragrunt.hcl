# environments/dev/vpc/terragrunt.hcl
# VPC configuration for DEV environment
# This is a Terragrunt file that wraps the Terraform module with environment-specific values

include {
  path = find_in_parent_folders("terragrunt.hcl")
}

# Define the Terraform module to use
terraform {
  source = "${get_parent_terragrunt_dir()}/modules/vpc"
}

# Input variables for the VPC module (environment-specific)
inputs = {
  environment = "dev"
  
  # Dev uses a smaller CIDR block
  vpc_cidr = "10.0.0.0/16"
  
  # Dev uses 2 public subnets and 2 private subnets
  public_subnet_cidrs = [
    "10.0.1.0/24",    # us-east-1a
    "10.0.2.0/24",    # us-east-1b
  ]
  
  private_subnet_cidrs = [
    "10.0.11.0/24",   # us-east-1a
    "10.0.12.0/24",   # us-east-1b
  ]
  
  # Availability zones
  availability_zones = [
    "us-east-1a",
    "us-east-1b",
  ]
  
  cost_center = "engineering"
  
  tags = {
    Environment = "dev"
    Project     = "terraform-automation"
    Owner       = "devops-team"
  }
}

# Environment-specific Terragrunt settings
skip = false  # Don't skip deployment

# Prevent accidental destroy in dev (optional)
# prevent_destroy = false
