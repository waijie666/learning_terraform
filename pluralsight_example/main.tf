##################################################################################
# PROVIDERS
##################################################################################

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = local.common_tags
  }
}

##################################################################################
# DATA
##################################################################################

data "aws_ssm_parameter" "ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
  #name = "/aws/service/canonical/ubuntu/server/22.04/stable/current/amd64/hvm/ebs-gp2/ami-id"
}

##################################################################################
# RESOURCES
##################################################################################

# NETWORKING #
resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_subnet" "subnet1" {
  cidr_block              = "10.0.0.0/24"
  vpc_id                  = aws_vpc.vpc.id
  map_public_ip_on_launch = true
}

# ROUTING #
resource "aws_route_table" "rtb" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "rta-subnet1" {
  subnet_id      = aws_subnet.subnet1.id
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

# Keypair #
resource "aws_key_pair" "ssh_key" {
  key_name = "ssh_key2"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAtVhFRIA6EBotGOe5SkH0qcw/ZiB8nvmacPLbP1RYF+Uov3pBXAgkButNnV8vqASfbqlyvTdU6uZuhskL7Sy0xIn5pe7+UbVb+dICSHpGM+Lve9qCxn8H6sRZwnELLwSiunNGdHhY/wo4gInyfo8g0BaL9uKFNgszjnuYDKd2m/NvIJUdpkzWmeGXOt0QHh8w/RXEKLfM0RNKPc1h2+VfFXAzLBEA1N9xeA6+zTQKA1+WbITeKtK4Do+qyiaHmzBTj8sBJLUhaOYKR6Hyja0rxXxr2OZubRW90CozsbHKSAKowGdHwB5no/P6L1L9NPF0Xlsb24GMgolKxVank0ct1w== rsa-key-20170503ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAtVhFRIA6EBotGOe5SkH0qcw/ZiB8nvmacPLbP1RYF+Uov3pBXAgkButNnV8vqASfbqlyvTdU6uZuhskL7Sy0xIn5pe7+UbVb+dICSHpGM+Lve9qCxn8H6sRZwnELLwSiunNGdHhY/wo4gInyfo8g0BaL9uKFNgszjnuYDKd2m/NvIJUdpkzWmeGXOt0QHh8w/RXEKLfM0RNKPc1h2+VfFXAzLBEA1N9xeA6+zTQKA1+WbITeKtK4Do+qyiaHmzBTj8sBJLUhaOYKR6Hyja0rxXxr2OZubRW90CozsbHKSAKowGdHwB5no/P6L1L9NPF0Xlsb24GMgolKxVank0ct1w== rsa-key-20170503"
}

# INSTANCES #
resource "aws_instance" "nginx1" {
  ami                    = nonsensitive(data.aws_ssm_parameter.ami.value)
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.subnet1.id
  vpc_security_group_ids = [aws_security_group.nginx-sg.id]
  key_name = "ssh_key2"
  root_block_device {
    volume_size = 15
  }
  user_data = <<EOF
#! /bin/bash
sudo amazon-linux-extras install -y nginx1
sudo service nginx start
sudo rm /usr/share/nginx/html/index.html
echo '<html><head><title>Taco Team Server</title></head><body style=\"background-color:#1F778D\"><p style=\"text-align: center;\"><span style=\"color:#FFFFFF;\"><span style=\"font-size:28px;\">You did it! Have a &#127790;</span></span></p></body></html>' | sudo tee /usr/share/nginx/html/index.html
EOF
}
