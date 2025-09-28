resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.project_name}-igw"
  }
}

resource "aws_subnet" "public" {
  for_each                = toset(var.availability_zones)
  vpc_id                  = aws_vpc.main.id
  availability_zone       = each.value
  cidr_block              = cidrsubnet(var.vpc_cidr_block, 8, index(var.availability_zones, each.value) * 2)
  map_public_ip_on_launch = true

  tags = {
    Name                                        = "${var.project_name}-public-${each.value}"
    "kubernetes.io/cluster/${var.project_name}" = "shared" # Tag for EKS Load Balancer discovery
    "kubernetes.io/role/elb"                    = "1"      # Tag for EKS Load Balancer discovery
  }
}

resource "aws_subnet" "private" {
  for_each          = toset(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  availability_zone = each.value
  cidr_block        = cidrsubnet(var.vpc_cidr_block, 8, index(var.availability_zones, each.value) * 2 + 1)

  tags = {
    Name                                        = "${var.project_name}-private-${each.value}"
    "kubernetes.io/cluster/${var.project_name}" = "shared" # Tag for EKS internal LB and node discovery
    "kubernetes.io/role/internal-elb"           = "1"      # Tag for EKS internal LB discovery
  }
}

resource "aws_eip" "nat" {
  for_each = toset(var.availability_zones)
  domain   = "vpc"
  tags = {
    Name = "${var.project_name}-nat-eip-${each.value}"
  }
}

resource "aws_nat_gateway" "main" {
  for_each      = toset(var.availability_zones)
  allocation_id = aws_eip.nat[each.value].id
  subnet_id     = aws_subnet.public[each.value].id
  tags = {
    Name = "${var.project_name}-nat-${each.value}"
  }
  depends_on = [aws_internet_gateway.main]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  for_each       = toset(var.availability_zones)
  subnet_id      = aws_subnet.public[each.value].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  for_each = toset(var.availability_zones)
  vpc_id   = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[each.value].id
  }
  tags = {
    Name = "${var.project_name}-private-rt-${each.value}"
  }
}

resource "aws_route_table_association" "private" {
  for_each       = toset(var.availability_zones)
  subnet_id      = aws_subnet.private[each.value].id
  route_table_id = aws_route_table.private[each.value].id
}