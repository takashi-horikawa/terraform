locals {
  subnets_a = {
    public = {
      cidr_block        = var.subnet_public_cidr_a
      availability_zone = "${var.region}a"
    }
    protected = {
      cidr_block        = var.subnet_protected_cidr_a
      availability_zone = "${var.region}a"
    }
    private = {
      cidr_block        = var.subnet_private_cidr_a
      availability_zone = "${var.region}a"
    }
  }
  subnets_c = {
    public = {
      cidr_block        = var.subnet_public_cidr_c
      availability_zone = "${var.region}c"
    }
    protected = {
      cidr_block        = var.subnet_protected_cidr_c
      availability_zone = "${var.region}c"
    }
    private = {
      cidr_block        = var.subnet_private_cidr_c
      availability_zone = "${var.region}c"
    }
  }
}

resource "aws_vpc" "main_vpc" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "${var.env}-${var.system_name}-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "${var.env}-${var.system_name}-igw"
  }
}

resource "aws_subnet" "subnets_a" {
  for_each          = local.subnets_a
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone

  tags = {
    Name = "${var.env}-${var.system_name}-${each.key}-subnet-${substr(each.value.availability_zone, -1, 1)}"
  }
}

resource "aws_route_table" "route_tables_a" {
  for_each = local.subnets_a
  vpc_id   = aws_vpc.main_vpc.id

  tags = {
    Name = "${var.env}-${var.system_name}-${each.key}-rt"
  }
}

resource "aws_route" "public_route_a" {
  for_each = {
    for k, v in local.subnets_a : k => v if k == "public"
  }
  route_table_id         = aws_route_table.route_tables_a["public"].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "route_table_associations_a" {
  for_each       = aws_subnet.subnets_a
  subnet_id      = each.value.id
  route_table_id = aws_route_table.route_tables_a[each.key].id
}


resource "aws_subnet" "subnets_c" {
  for_each          = local.subnets_c
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone

  tags = {
    Name = "${var.env}-${var.system_name}-${each.key}-subnet-${substr(each.value.availability_zone, -1, 1)}"
  }
}

#resource "aws_route_table" "route_tables_c" {
#  for_each = local.subnets_c
#  vpc_id   = aws_vpc.main_vpc.id
#
#  tags = {
#    Name = "${var.env}-${var.system_name}-${each.key}-rt"
#  }
#}

resource "aws_route" "public_route_c" {
  for_each = {
    for k, v in local.subnets_c : k => v if k == "public"
  }
  route_table_id         = aws_route_table.route_tables_a["public"].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "route_table_associations_c" {
  for_each       = aws_subnet.subnets_c
  subnet_id      = each.value.id
  route_table_id = aws_route_table.route_tables_a[each.key].id
}

resource "aws_eip" "nat_eip" {
  #  vpc = true
  count  = 1  // 作成するEIPの数
  domain = "vpc"  // VPC内でEIPを使用（vpc = trueの代わりに）

  tags = {
    Name = "${var.env}-${var.system_name}-nat-eip"
  }
}

resource "aws_nat_gateway" "nat_gw" {
  count = 1 
  allocation_id = aws_eip.nat_eip[count.index].id
  subnet_id     = aws_subnet.subnets_a["public"].id

  tags = {
    Name = "${var.env}-${var.system_name}-natgw"
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_route" "protected_route_a" {
  route_table_id         = aws_route_table.route_tables_a["protected"].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gw[0].id
}

#resource "aws_route" "protected_route_c" {
#  route_table_id         = aws_route_table.route_tables_c["protected"].id
#  destination_cidr_block = "0.0.0.0/0"
#  nat_gateway_id         = aws_nat_gateway.nat_gw[0].id
#}

