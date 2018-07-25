provider "aws" {
  region                  = "ap-southeast-2"
  shared_credentials_file = "~/.aws/credentials"
  profile                 = "${terraform.workspace == "production" ? "AU-prod": "AU-non-prod"}"
}

resource "aws_lb" "alb" {
  name               = "${terraform.workspace == "production" ? format("%s%s", "alb-au-prod-", var.alb_name) :  format("%s%s", "alb-au-nonprod-" , var.alb_name)}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${split(",", terraform.workspace == "production" ? join(",", list(aws_security_group.sg.id)) : join(",", concat(var.sg_non_prod_additional_groups, list(aws_security_group.sg.id))))}"]
  subnets            = ["${split(",", terraform.workspace == "production" ? join(",", var.subnets_prod) : join(",",var.subnets_non_prod))}"]

  enable_deletion_protection = false
}

resource "aws_lb_listener" "front_end_http" {
  load_balancer_arn = "${aws_lb.alb.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_lb_target_group.main.arn}"
    type             = "forward"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# This listener is just for prod as the ACM thumbprint only exists in prod
resource "aws_lb_listener" "front_end_https" {
  load_balancer_arn = "${aws_lb.alb.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2015-05"
  certificate_arn   = "${terraform.workspace == "production" ? var.https_cert_arn_prod :  var.https_cert_arn_non_prod}"

  default_action {
    target_group_arn = "${aws_lb_target_group.main.arn}"
    type             = "forward"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener_rule" "websockets" {
  listener_arn = "${aws_lb_listener.front_end_http.arn}"
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.websocket.arn}"
  }

  condition {
    field  = "path-pattern"
    values = ["/signalr"]
  }
}

resource "aws_lb_target_group" "main" {
  name     = "${terraform.workspace == "production" ? format("%s%s", "tg-au-prod-", var.main_target_group_name) :  format("%s%s", "tg-au-nonprod-" , var.main_target_group_name)}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${terraform.workspace == "production" ? var.vpc_prod_id :  var.vpc_non_prod_id}"

  health_check {
    healthy_threshold = "5"
    unhealthy_threshold = "2"
    path = "/health.html"
    interval = "30"
    matcher = "200"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# This is required to make websockets work as they need sticky cookies

resource "aws_lb_target_group" "websocket" {
  name     = "${terraform.workspace == "production" ? format("%s%s", "tg-au-prod-", var.websocket_target_group_name) :  format("%s%s", "tg-au-nonprod-" , var.websocket_target_group_name)}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${terraform.workspace == "production" ? var.vpc_prod_id :  var.vpc_non_prod_id}"

  stickiness {
    type = "lb_cookie"
    cookie_duration = "86400"
  }

  health_check {
    healthy_threshold = "5"
    unhealthy_threshold = "2"
    path = "/health.html"
    interval = "30"
    matcher = "200"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group_attachment" "main" {
  target_group_arn = "${aws_lb_target_group.main.arn}"
  target_id        = "${terraform.workspace == "production" ? var.app_instance_id_prod :  var.app_instance_id_non_prod}"
  port             = 80
}

resource "aws_lb_target_group_attachment" "websocket" {
  target_group_arn = "${aws_lb_target_group.websocket.arn}"
  target_id        = "${terraform.workspace == "production" ? var.app_instance_id_prod :  var.app_instance_id_non_prod}"
  port             = 80
}

resource "aws_security_group" "sg" {
  name        = "${terraform.workspace == "production" ? format("%s%s", "sg_prod_", var.sg_group_name) :  format("%s%s", "sg_nonprod_" , var.sg_group_name)}"
  description = "Allow all HTTP & HTTPS inbound traffic"
  vpc_id      = "${terraform.workspace == "production" ? var.vpc_prod_id :  var.vpc_non_prod_id}"

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "elb_in_http" {
  type            = "ingress"
  from_port       = 80
  to_port         = 80
  protocol        = "tcp"
  source_security_group_id = "${aws_security_group.sg.id}"
  security_group_id = "${terraform.workspace == "production" ? var.sg_prod_app_id :  var.sg_non_prod_app_id}"
}

resource "aws_security_group_rule" "elb_in_https" {
  type            = "ingress"
  from_port       = 443
  to_port         = 443
  protocol        = "tcp"
  source_security_group_id = "${aws_security_group.sg.id}"
  security_group_id = "${terraform.workspace == "production" ? var.sg_prod_app_id :  var.sg_non_prod_app_id}"
}

# This adds 0.0.0.0 access rule for the public LB in prod environment

resource "aws_security_group_rule" "elb_ext_in_http" {
  count = "${terraform.workspace == "production" ? 1 : 0}"
  type            = "ingress"
  from_port       = 80
  to_port         = 80
  protocol        = "tcp"
  cidr_blocks     = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
  security_group_id = "${aws_security_group.sg.id}"
}


resource "aws_security_group_rule" "elb_in_ext_https" {
  count = "${terraform.workspace == "production" ? 1 : 0}"
  type            = "ingress"
  from_port       = 443
  to_port         = 443
  protocol        = "tcp"
  cidr_blocks     = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
  security_group_id = "${aws_security_group.sg.id}"
}

### Data

data "aws_instance" "app1" {
  instance_id = "${terraform.workspace == "production" ? var.app_instance_id_prod :  var.app_instance_id_non_prod}"
}

data "aws_lb" "alb" {
  arn  = "${aws_lb.alb.id}"
}
