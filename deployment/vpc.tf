provider "aws" {
  region = var.region
}

locals {
  mgmt_subnet    = cidrsubnet(var.vpc_cidr, 8, 1)
  public_subnet  = cidrsubnet(var.vpc_cidr, 8, 2)
  private_subnet = cidrsubnet(var.vpc_cidr, 8, 3)
}

#
# Create a random id
#
resource "random_id" "id" {
  byte_length = 2
  prefix      = var.prefix
}

#
# Get availability zones in region
#
data "aws_availability_zones" "this" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

#
# Create the VPC
#
#tfsec:ignore:aws-ec2-no-public-ip-subnet tfsec:ignore:aws-ec2-require-vpc-flow-logs-for-all-vpcs
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name                 = "${random_id.id.dec}-vpc"
  cidr                 = var.vpc_cidr
  azs                  = slice(data.aws_availability_zones.this.names, 0, 1)
  public_subnets       = [local.public_subnet]
  private_subnets      = [local.private_subnet]
  enable_dns_hostnames = true
  enable_nat_gateway   = true
  create_igw           = true

  tags = {
    Name = "${random_id.id.dec}-vpc"
  }
}

resource "aws_subnet" "mgmt" {
  vpc_id            = module.vpc.vpc_id
  cidr_block        = local.mgmt_subnet
  availability_zone = data.aws_availability_zones.this.names[0]

  tags = {
    Name = "${random_id.id.dec}-management"
  }
}

resource "aws_route_table" "mgmt" {
  vpc_id = module.vpc.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = module.vpc.igw_id
  }
}

resource "aws_route_table_association" "mgmt" {
  subnet_id      = aws_subnet.mgmt.id
  route_table_id = aws_route_table.mgmt.id
}
