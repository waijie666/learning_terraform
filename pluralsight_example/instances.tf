data "aws_ssm_parameter" "ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
  #name = "/aws/service/canonical/ubuntu/server/22.04/stable/current/amd64/hvm/ebs-gp2/ami-id"
}

# Keypair #
resource "aws_key_pair" "ssh_key" {
  key_name   = "ssh_key2"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAtVhFRIA6EBotGOe5SkH0qcw/ZiB8nvmacPLbP1RYF+Uov3pBXAgkButNnV8vqASfbqlyvTdU6uZuhskL7Sy0xIn5pe7+UbVb+dICSHpGM+Lve9qCxn8H6sRZwnELLwSiunNGdHhY/wo4gInyfo8g0BaL9uKFNgszjnuYDKd2m/NvIJUdpkzWmeGXOt0QHh8w/RXEKLfM0RNKPc1h2+VfFXAzLBEA1N9xeA6+zTQKA1+WbITeKtK4Do+qyiaHmzBTj8sBJLUhaOYKR6Hyja0rxXxr2OZubRW90CozsbHKSAKowGdHwB5no/P6L1L9NPF0Xlsb24GMgolKxVank0ct1w== rsa-key-20170503ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAtVhFRIA6EBotGOe5SkH0qcw/ZiB8nvmacPLbP1RYF+Uov3pBXAgkButNnV8vqASfbqlyvTdU6uZuhskL7Sy0xIn5pe7+UbVb+dICSHpGM+Lve9qCxn8H6sRZwnELLwSiunNGdHhY/wo4gInyfo8g0BaL9uKFNgszjnuYDKd2m/NvIJUdpkzWmeGXOt0QHh8w/RXEKLfM0RNKPc1h2+VfFXAzLBEA1N9xeA6+zTQKA1+WbITeKtK4Do+qyiaHmzBTj8sBJLUhaOYKR6Hyja0rxXxr2OZubRW90CozsbHKSAKowGdHwB5no/P6L1L9NPF0Xlsb24GMgolKxVank0ct1w== rsa-key-20170503"
}

# INSTANCES #
resource "aws_instance" "nginx" {
  count                  = var.redundancy_count
  ami                    = nonsensitive(data.aws_ssm_parameter.ami.value)
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.subnets[count.index % length(aws_subnet.subnets)].id
  vpc_security_group_ids = [aws_security_group.nginx-sg.id]
  iam_instance_profile   = aws_iam_instance_profile.nginx_profile.name
  depends_on             = [aws_iam_role_policy.allow_s3_all]
  key_name               = "ssh_key2"
  root_block_device {
    volume_size = 8
  }
  user_data = <<EOF
#! /bin/bash
sudo amazon-linux-extras install -y nginx1
sudo service nginx start
aws s3 cp s3://${aws_s3_bucket.web_bucket.id}/website/index.html /home/ec2-user/index.html
aws s3 cp s3://${aws_s3_bucket.web_bucket.id}/website/Globo_logo_Vert.png /home/ec2-user/Globo_logo_Vert.png
sudo rm /usr/share/nginx/html/index.html
sudo cp /home/ec2-user/index.html /usr/share/nginx/html/index.html
sudo cp /home/ec2-user/Globo_logo_Vert.png /usr/share/nginx/html/Globo_logo_Vert.png
EOF
}