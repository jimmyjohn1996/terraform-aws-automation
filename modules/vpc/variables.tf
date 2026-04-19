# modules/vpc/variables.tf
# Input variables for the VPC module

variable "environment" {
  type        = string
  description = "Environment name (dev, staging, prod)"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for VPC"
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "Must be a valid CIDR block."
  }
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "List of CIDR blocks for public subnets"
  validation {
    condition = alltrue([
      for cidr in var.public_subnet_cidrs : can(cidrhost(cidr, 0))
    ])
    error_message = "All must be valid CIDR blocks."
  }
}


variable "availability_zones" {
  type        = list(string)
  description = "List of availability zones"
  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "Must specify at least 2 availability zones for HA."
  }
}

variable "cost_center" {
  type        = string
  description = "Cost center for billing/tagging"
  default     = "engineering"
}

variable "tags" {
  type        = map(string)
  description = "Additional tags to apply to resources"
  default     = {}
}
