data "aws_availability_zones" "available" {
  state  = "available"
  region = "us-east-1"
}

resource "aws_vpc" "meal_tracker_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true


  tags = {
    Name = "meal_tracker_vpc"
  }
}

resource "aws_subnet" "meal_tracker_subnet" {
  count             = length(var.subnets)
  vpc_id            = aws_vpc.meal_tracker_vpc.id
  cidr_block        = var.subnets[count.index].cidr_block
  availability_zone = var.subnets[count.index].availability_zone
  depends_on        = [aws_vpc.meal_tracker_vpc]

  tags = {
    Name = "meal_tracker_subnet_${var.subnets[count.index].public ? "public" : "private"}_${count.index + 1}"
  }

  lifecycle {
    precondition {
      condition     = contains(data.aws_availability_zones.available.names, var.subnets[count.index].availability_zone)
      error_message = "The availability zone ${var.subnets[count.index].availability_zone} is not valid in the current region."
    }
  }
}

resource "aws_internet_gateway" "meal_tracker_igw" {
  vpc_id = aws_vpc.meal_tracker_vpc.id

  tags = {
    Name = "meal_tracker_igw"
  }

  depends_on = [aws_vpc.meal_tracker_vpc]

}

resource "aws_route_table" "meal_tracker_rt_public" {
  vpc_id = aws_vpc.meal_tracker_vpc.id

  tags = {
    Name = "meal_tracker_public_rt"
  }

  depends_on = [aws_internet_gateway.meal_tracker_igw, aws_subnet.meal_tracker_subnet]
}

resource "aws_route" "meal_tracker_public_route" {
  route_table_id         = aws_route_table.meal_tracker_rt_public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.meal_tracker_igw.id
  depends_on             = [aws_internet_gateway.meal_tracker_igw]

}

resource "aws_route_table" "meal_tracker_rt_private" {
  vpc_id = aws_vpc.meal_tracker_vpc.id

  tags = {
    Name = "meal_tracker_private_rt"
  }

  depends_on = [aws_subnet.meal_tracker_subnet]


}

resource "aws_route_table_association" "meal_tracker_rt_assoc" {
  count          = length(var.subnets)
  subnet_id      = aws_subnet.meal_tracker_subnet[count.index].id
  route_table_id = var.subnets[count.index].public ? aws_route_table.meal_tracker_rt_public.id : aws_route_table.meal_tracker_rt_private.id

  depends_on = [aws_subnet.meal_tracker_subnet, aws_route_table.meal_tracker_rt_public, aws_route_table.meal_tracker_rt_private]
}

resource "aws_eip" "meal_tracker_nat_eip" {
  count = local.create_nat ? 1 : 0

  tags = {
    Name = "meal_tracker_nat_eip"
  }
}

resource "aws_nat_gateway" "meal_tracker_nat_gw" {
  count         = local.create_nat ? 1 : 0
  allocation_id = aws_eip.meal_tracker_nat_eip[0].id
  subnet_id = aws_subnet.meal_tracker_subnet[
    index(var.subnets, one([for s in var.subnets : s if s.public]))
  ].id
  depends_on = [aws_internet_gateway.meal_tracker_igw, aws_subnet.meal_tracker_subnet, aws_eip.meal_tracker_nat_eip]

  tags = {
    Name = "meal_tracker_nat_gw_${count.index + 1}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route" "meal_tracker_private_route" {
  count                  = local.create_nat ? 1 : 0
  route_table_id         = aws_route_table.meal_tracker_rt_private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.meal_tracker_nat_gw[0].id
  depends_on             = [aws_nat_gateway.meal_tracker_nat_gw]
}


resource "aws_security_group" "web_sg" {
  name        = "meal_tracker_web_sg"
  description = "Allow HTTP and HTTPS traffic"
  vpc_id      = aws_vpc.meal_tracker_vpc.id

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  depends_on = [aws_vpc.meal_tracker_vpc]

}

resource "aws_security_group" "app_sg" {
  name        = "meal_tracker_app_sg"
  description = "Allow traffic from web servers"
  vpc_id      = aws_vpc.meal_tracker_vpc.id

  ingress {
    security_groups = [aws_security_group.web_sg.id]
    protocol        = "tcp"
    from_port       = 8080
    to_port         = 8080
  }

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
  }

  depends_on = [aws_vpc.meal_tracker_vpc, aws_security_group.web_sg]

}

resource "aws_security_group" "db_sg" {
  name        = "meal_tracker_db_sg"
  description = "Allow traffic from app servers"
  vpc_id      = aws_vpc.meal_tracker_vpc.id

  ingress {
    security_groups = [aws_security_group.app_sg.id]
    protocol        = "tcp"
    from_port       = 5432
    to_port         = 5432
  }

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
  }

  depends_on = [aws_vpc.meal_tracker_vpc, aws_security_group.app_sg]

}
