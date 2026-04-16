# environments/prod/vpc/terragrunt.hcl
# VPC configuration for PROD environment
# Notice how similar this is to dev - that's the DRY principle at work!
# Only the values are different, not the structure

include {
  path = find_in_parent_folders()
}

terraform {
  source = "${get_parent_terragrunt_dir()}/modules/vpc"
}

inputs = {
  environment = "prod"
  
  # Prod uses a larger CIDR block for growth
  vpc_cidr = "10.1.0.0/16"
  
  # Prod uses 3 public and 3 private subnets (more AZs for HA)
  public_subnet_cidrs = [
    "10.1.1.0/24",    # us-east-1a
    "10.1.2.0/24",    # us-east-1b
    "10.1.3.0/24",    # us-east-1c
  ]
  
  private_subnet_cidrs = [
    "10.1.11.0/24",   # us-east-1a
    "10.1.12.0/24",   # us-east-1b
    "10.1.13.0/24",   # us-east-1c
  ]
  
  availability_zones = [
    "us-east-1a",
    "us-east-1b",
    "us-east-1c",
  ]
  
  cost_center = "operations"
  
  tags = {
    Environment = "prod"
    Project     = "terraform-automation"
    Owner       = "devops-team"
    CriticalService = "true"
  }
}

# Prevent accidental destruction in production
# prevent_destroy = true
