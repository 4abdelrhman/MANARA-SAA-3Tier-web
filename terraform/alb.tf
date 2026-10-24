resource "aws_lb" "this" {
  name               = "${local.name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [for subnet in aws_subnet.public : subnet.id]

  enable_http2               = true
  drop_invalid_header_fields = true
  enable_deletion_protection = false
  idle_timeout               = 60
  preserve_host_header       = false
  xff_header_processing_mode = "append"

  tags = {
    Name = "${local.name}-alb"
  }
}

resource "aws_lb_target_group" "app" {
  name                 = "${local.name}-tg"
  port                 = local.app_port
  protocol             = "HTTP"
  target_type          = "instance"
  vpc_id               = aws_vpc.main.id
  deregistration_delay = 30

  load_balancing_algorithm_type = "least_outstanding_requests"

  health_check {
    enabled             = true
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
  }

  tags = {
    Name = "${local.name}-tg"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = local.custom_domain_enabled ? "redirect" : "forward"
    target_group_arn = local.custom_domain_enabled ? null : aws_lb_target_group.app.arn

    dynamic "redirect" {
      for_each = local.custom_domain_enabled ? [1] : []

      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }

  tags = {
    Name = "${local.name}-http-listener"
  }
}

resource "aws_lb_listener" "https" {
  count = local.custom_domain_enabled ? 1 : 0

  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate_validation.app[0].certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }

  tags = {
    Name = "${local.name}-https-listener"
  }
}

# Explicit layer 7 path rule. The same target group serves static files, so this
# demonstrates path-based routing without duplicating application capacity.
resource "aws_lb_listener_rule" "static" {
  listener_arn = local.custom_domain_enabled ? one(aws_lb_listener.https[*].arn) : aws_lb_listener.http.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }

  condition {
    path_pattern {
      values = ["/static/*"]
    }
  }

  tags = {
    Name = "${local.name}-static-rule"
  }
}
