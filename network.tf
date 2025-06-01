resource "aws_vpc" "khm_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true

  tags = {
    "Name" = "khm_vpc"
  }
}

resource "aws_subnet" "khm_subnet_private" {
  vpc_id     = aws_vpc.khm_vpc.id
  cidr_block = var.private_subnet

  tags = {
    "Name" = "khm_subnet_private"
  }
}

resource "aws_subnet" "khm_subnet_public" {
  vpc_id                  = aws_vpc.khm_vpc.id
  cidr_block              = var.public_subnet
  map_public_ip_on_launch = true

  tags = {
    "Name" = "khm_subnet_public"
  }
}

resource "aws_internet_gateway" "khm_internet_gateway" {
  vpc_id = aws_vpc.khm_vpc.id

  tags = {
    "Name" = "khm_internet_gateway"
  }
}

resource "aws_route_table" "khm_route_table_public" {
  vpc_id = aws_vpc.khm_vpc.id

  route {
    cidr_block = "0.0.0.0/0" # route for internet traffic
    gateway_id = aws_internet_gateway.khm_internet_gateway.id
  }

  tags = {
    "Name" = "khm_route_table_public"
  }
}

resource "aws_route_table_association" "khm_route_table_subnet_public" {
  subnet_id      = aws_subnet.khm_subnet_public.id
  route_table_id = aws_route_table.khm_route_table_public.id
}

resource "aws_eip" "khm_eip" {
  # 'vpc = true' is the default and does not need to be specified

  tags = {
    "Name" = "khm_eip"
  }
}

resource "aws_nat_gateway" "khm_nat_gateway" {
  allocation_id = aws_eip.khm_eip.id
  subnet_id     = aws_subnet.khm_subnet_public.id
  depends_on    = [aws_internet_gateway.khm_internet_gateway]

  tags = {
    "Name" = "khm_nat_gateway"
  }
}

resource "aws_route_table" "khm_route_table_private" {
  vpc_id = aws_vpc.khm_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.khm_nat_gateway.id
  }

  tags = {
    "Name" = "khm_route_table_private"
  }
}

resource "aws_route_table_association" "khm_route_table_subnet_private" {
  subnet_id      = aws_subnet.khm_subnet_private.id
  route_table_id = aws_route_table.khm_route_table_private.id
}

resource "aws_security_group" "khm_security_group" {
  name        = "khm_security_group"
  description = "Security group for ARM EC2 instance"
  vpc_id      = aws_vpc.khm_vpc.id

  tags = {
    "Name" = "khm_security_group"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = 6 # TCP
    cidr_blocks = [var.user_source_ip]
    description = "Allow SSH ingress"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = 6
    cidr_blocks = ["0.0.0.0/0"] # internet traffic
    description = "Allow HTTP ingress"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = 6
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS ingress"
  }

  ingress {
    from_port   = 0    # applies to all ports
    to_port     = 0    # applies to all ports
    protocol    = -1   # applies to all protocols (TCP, UDP, ICMP, etc.)
    self        = true # allows communication within the same security group
    description = "Allow traffic in security group"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    self        = true
    description = "Allow traffic in security group"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all egress"
  }

  ingress {
    from_port   = 8 # ping
    to_port     = 0
    protocol    = 1 # ICMP
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow ICMP ingress"
  }
}
