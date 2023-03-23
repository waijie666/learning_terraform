data "aws_ssm_parameter" "ami" {
  #name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
  name = "/aws/service/canonical/ubuntu/server/22.04/stable/current/amd64/hvm/ebs-gp2/ami-id"
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
  user_data = templatefile("${path.module}/startup_script.tpl", {
    s3_bucket_name = aws_s3_bucket.web_bucket.id
  })

  tags = {
    name = "nginx-${count.index}"
  }
}

resource "aws_launch_template" "ec2_scaling_template_example" {
  image_id               = nonsensitive(data.aws_ssm_parameter.ami.value)
  instance_type          = "t2.micro"
  key_name               = "ssh_key2"
  vpc_security_group_ids = [aws_security_group.nginx-sg.id]
  iam_instance_profile {
    name = aws_iam_instance_profile.nginx_profile.name
  }
  user_data = base64encode(templatefile("${path.module}/startup_script.tpl", {
    s3_bucket_name = aws_s3_bucket.web_bucket.id
  }))

  tags = {
    name = "ec2-scaling"
  }
  name_prefix = "ec2-scaling"
}

resource "aws_autoscaling_group" "ec2_scaling" {
  desired_capacity        = 3
  max_size                = 9
  min_size                = 3
  default_instance_warmup = 60
  vpc_zone_identifier     = aws_subnet.subnets.*.id
  launch_template {
    id = aws_launch_template.ec2_scaling_template_example.id
  }
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }
  target_group_arns = [aws_lb_target_group.nginx.arn]
}

resource "aws_autoscaling_policy" "example" {
  autoscaling_group_name = aws_autoscaling_group.ec2_scaling.name
  name                   = "Autoscale"
  policy_type            = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 20.0
  }
}
