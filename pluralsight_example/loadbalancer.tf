##################################################################################
# DATA
##################################################################################

data "aws_elb_service_account" "root" {}


##################################################################################
# RESOURCES
##################################################################################

resource "aws_lb" "nginx" {
  name                       = "globo-web-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.nginx-alb-sg.id]
  subnets                    = aws_subnet.subnets.*.id
  enable_deletion_protection = false

  access_logs {
    bucket  = aws_s3_bucket.web_bucket.bucket
    prefix  = "alb-logs"
    enabled = true
  }
}

resource "aws_lb_target_group" "nginx" {
  name                 = "nginx-alb-tg"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = aws_vpc.vpc.id
  deregistration_delay = 60
}

resource "aws_lb_listener" "nginx" {
  load_balancer_arn = aws_lb.nginx.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nginx.arn
  }
}

resource "aws_lb_target_group_attachment" "nginx" {
  count            = var.redundancy_count
  target_group_arn = aws_lb_target_group.nginx.arn
  target_id        = aws_instance.nginx[count.index].id
  port             = 80
}