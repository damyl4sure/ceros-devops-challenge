# Create VPC Terraform Module
#https://github.com/terraform-aws-modules/terraform-aws-vpc/blob/master/examples/complete-vpc/main.tf

locals {
  name   = "ceros-ski-${var.environment}"
  region = "us-east-1" 
  
  common_tags = {
    Application = "ceros-ski" 
    Environment = var.environment
    Name = "ceros-ski-${var.environment}-main_vpc"
    Resource = "modules.environment.aws_vpc.main_vpc"
  }
} 



module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.7.0"

  # VPC Basic Details
  name = "${local.name}-${var.vpc_name}"
  cidr = var.vpc_cidr_block
  azs             = var.vpc_availability_zones
  public_subnets  = var.vpc_public_subnets
  private_subnets = var.vpc_private_subnets  

  create_database_subnet_group = var.vpc_create_database_subnet_group
  
  # NAT Gateways - Outbound Communication
  enable_nat_gateway = var.vpc_enable_nat_gateway 
  single_nat_gateway = var.vpc_single_nat_gateway

  # VPC DNS Parameters
  enable_dns_hostnames = true
  enable_dns_support   = true


  tags = local.common_tags
  vpc_tags = local.common_tags

  # Additional Tags to Subnets
  public_subnet_tags = {
    Type = "Public Subnets"
    Name = "Public Subnets"
  }
  private_subnet_tags = {
    Type = "Private Subnets"
    Name = "Private Subnets"
  } 
}