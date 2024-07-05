locals {
  mgmt_supernet     = cidrsubnet(var.aws_vpc_cidr, 4, 1)
  external_supernet = cidrsubnet(var.aws_vpc_cidr, 4, 2)
  internal_supernet = cidrsubnet(var.aws_vpc_cidr, 4, 3)
}

resource "aws_vpc" "main" {
  cidr_block           = var.aws_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = local.name_prefix
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = local.name_prefix
  }
}

data "aws_availability_zones" "available" {
  state = "available"

  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

resource "aws_subnet" "external" {
  count = var.aws_az_count

  cidr_block        = cidrsubnet(local.external_supernet, 4, count.index)
  vpc_id            = aws_vpc.main.id
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${local.name_prefix}-external-${count.index}"
  }
}

resource "aws_route_table" "external" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
}

resource "aws_route_table_association" "external" {
  count = var.aws_az_count

  subnet_id      = aws_subnet.external[count.index].id
  route_table_id = aws_route_table.external.id
}

resource "aws_eip" "this" {}

# resource "aws_nat_gateway" "this" {
#   depends_on = [aws_internet_gateway.this]

#   allocation_id = aws_eip.this.id
#   subnet_id     = aws_subnet.external[0].id

#   tags = {
#     Name = local.name_prefix
#   }
# }

resource "aws_subnet" "internal" {
  count = var.aws_az_count

  cidr_block        = cidrsubnet(local.internal_supernet, 4, count.index)
  vpc_id            = aws_vpc.main.id
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${local.name_prefix}-internal-${count.index}"
  }
}

resource "aws_route_table" "internal" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    # gateway_id = aws_nat_gateway.this.id
    gateway_id = aws_internet_gateway.this.id
  }
}

resource "aws_route_table_association" "internal" {
  count = var.aws_az_count

  subnet_id      = aws_subnet.internal[count.index].id
  route_table_id = aws_route_table.internal.id
}


resource "aws_subnet" "mgmt" {
  count = var.aws_az_count

  cidr_block        = cidrsubnet(local.mgmt_supernet, 4, count.index)
  vpc_id            = aws_vpc.main.id
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${random_id.id.dec}-management"
  }
}

resource "aws_route_table" "mgmt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
}

resource "aws_route_table_association" "mgmt" {
  count = var.aws_az_count

  subnet_id      = aws_subnet.mgmt[count.index].id
  route_table_id = aws_route_table.mgmt.id
}
