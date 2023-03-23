##################################################################################
# DATA
##################################################################################

data "aws_availability_zones" "available" {
  state = "available"
}


##################################################################################
# RESOURCES
##################################################################################

# NETWORKING #
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true
}

resource "aws_vpc_ipv4_cidr_block_association" "secondary_cidr" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.1.0.0/16"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_subnet" "subnets" {
  count                   = (var.redundancy_count > length(data.aws_availability_zones.available.names)) ? length(data.aws_availability_zones.available.names) : var.redundancy_count
  cidr_block              = cidrsubnet(var.vpc_cidr_block, 8, count.index)
  vpc_id                  = aws_vpc.vpc.id
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]
}

resource "aws_subnet" "rds-subnets" {
  count             = (var.redundancy_count > length(data.aws_availability_zones.available.names)) ? length(data.aws_availability_zones.available.names) : var.redundancy_count
  cidr_block        = cidrsubnet("10.1.0.0/16", 8, count.index)
  vpc_id            = aws_vpc.vpc.id
  availability_zone = data.aws_availability_zones.available.names[count.index]
  depends_on        = [aws_vpc_ipv4_cidr_block_association.secondary_cidr]
}


# ROUTING #
resource "aws_route_table" "rtb" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "rta-subnets" {
  count          = (var.redundancy_count > length(data.aws_availability_zones.available.names)) ? length(data.aws_availability_zones.available.names) : var.redundancy_count
  subnet_id      = aws_subnet.subnets[count.index].id
  route_table_id = aws_route_table.rtb.id
}

resource "aws_route_table_association" "rta-rds-subnets" {
  count          = (var.redundancy_count > length(data.aws_availability_zones.available.names)) ? length(data.aws_availability_zones.available.names) : var.redundancy_count
  subnet_id      = aws_subnet.rds-subnets[count.index].id
  route_table_id = aws_route_table.rtb.id
}


# SECURITY GROUPS #
# Nginx security group 
resource "aws_security_group" "nginx-sg" {
  name   = "nginx_sg"
  vpc_id = aws_vpc.vpc.id

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "nginx-alb-sg" {
  name   = "nginx_alb_sg"
  vpc_id = aws_vpc.vpc.id

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "rds-sg" {
  name   = "rds_sg"
  vpc_id = aws_vpc.vpc.id

  # HTTP access from anywhere
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }
}



