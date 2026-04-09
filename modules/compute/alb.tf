resource "aws_security_group" "sg-alb" {
  name        = "https-restricted"
  description = "Allow HTTPS only from specific IP"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow HTTPS from specific IP"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["163.49.24.253/32"]
  }

  ingress {
    description = "Allow HTTPS from All"
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

  tags = {
    Name = "${var.env}-${var.system_name}-alb-sg"
  }
}

resource "aws_lb" "alb" {
  name                             = "${var.env}-${var.system_name}-alb"
  internal                         = false
  idle_timeout                     = 60
  enable_deletion_protection       = true
  enable_cross_zone_load_balancing = true

  subnets = [ 
    var.subnets_a["public"].id,
    var.subnets_c["public"].id
  ]   

  security_groups = [
    aws_security_group.sg-alb.id
  ] 

  tags = {
    Name = "${var.env}-${var.system_name}-alb"
  }
}

resource "aws_alb_target_group" "alb-target" {
  name     = "${var.env}-${var.system_name}-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    interval            = 30
    path                = "/index.html"
    port                = 80
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
    matcher             = 200
  }
}

resource "aws_alb_target_group_attachment" "web1" {
  target_group_arn = aws_alb_target_group.alb-target.arn
  target_id        = aws_instance.web1.id
  port             = 80
}

resource "aws_alb_target_group_attachment" "web2" {
    target_group_arn = aws_alb_target_group.alb-target.arn
    target_id        = aws_instance.web2.id
    port             = 80
}

resource "aws_alb_listener" "alb" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    target_group_arn = aws_alb_target_group.alb-target.arn
    type             = "forward"
  }
}

resource "aws_alb_listener_rule" "tg2" {
  listener_arn = "${aws_alb_listener.alb.arn}"
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.alb-target.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}
