# modules/vpc/outputs.tf
# Output values from the VPC module for use in other modules

output "vpc_id" {
  value       = aws_vpc.main.id
  description = "VPC ID"
}

output "vpc_cidr" {
  value       = aws_vpc.main.cidr_block
  description = "VPC CIDR block"
}

output "internet_gateway_id" {
  value       = aws_internet_gateway.main.id
  description = "Internet Gateway ID"
}

output "public_subnet_ids" {
  value       = [for subnet in aws_subnet.public : subnet.id]
  description = "List of public subnet IDs"
}

output "public_route_table_id" {
  value       = aws_route_table.public.id
  description = "Public route table ID"
}


output "availability_zones" {
  value       = var.availability_zones
  description = "List of availability zones in use"
}

output "public_subnet_cidrs" {
  value       = var.public_subnet_cidrs
  description = "CIDR blocks of public subnets"
}
