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

output "private_subnet_ids" {
  value       = [for subnet in aws_subnet.private : subnet.id]
  description = "List of private subnet IDs"
}

output "nat_gateway_ids" {
  value       = [for nat in aws_nat_gateway.main : nat.id]
  description = "List of NAT Gateway IDs"
}

output "nat_gateway_ips" {
  value       = [for eip in aws_eip.nat : eip.public_ip]
  description = "Public IPs of NAT Gateways"
}

output "public_route_table_id" {
  value       = aws_route_table.public.id
  description = "Public route table ID"
}

output "private_route_table_ids" {
  value       = [for rt in aws_route_table.private : rt.id]
  description = "List of private route table IDs"
}

output "availability_zones" {
  value       = var.availability_zones
  description = "List of availability zones in use"
}

output "public_subnet_cidrs" {
  value       = var.public_subnet_cidrs
  description = "CIDR blocks of public subnets"
}

output "private_subnet_cidrs" {
  value       = var.private_subnet_cidrs
  description = "CIDR blocks of private subnets"
}
