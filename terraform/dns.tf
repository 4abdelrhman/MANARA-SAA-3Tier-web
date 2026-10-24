resource "aws_acm_certificate" "app" {
  count = local.custom_domain_enabled ? 1 : 0

  domain_name       = local.app_fqdn
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true

    precondition {
      condition     = var.hosted_zone_id != ""
      error_message = "hosted_zone_id is required when domain_name is set."
    }
  }

  tags = {
    Name = "${local.name}-certificate"
  }
}

resource "aws_route53_record" "certificate_validation" {
  for_each = {
    for option in flatten(aws_acm_certificate.app[*].domain_validation_options) : option.domain_name => {
      name   = option.resource_record_name
      record = option.resource_record_value
      type   = option.resource_record_type
    }
  }

  zone_id         = var.hosted_zone_id
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  ttl             = 60
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "app" {
  count = local.custom_domain_enabled ? 1 : 0

  certificate_arn         = aws_acm_certificate.app[0].arn
  validation_record_fqdns = [for record in aws_route53_record.certificate_validation : record.fqdn]
}

resource "aws_route53_health_check" "app" {
  count = local.custom_domain_enabled ? 1 : 0

  fqdn              = local.app_fqdn
  port              = 443
  type              = "HTTPS"
  resource_path     = "/health"
  request_interval  = 30
  failure_threshold = 3
  enable_sni        = true
  measure_latency   = true

  tags = {
    Name = "${local.name}-health-check"
  }
}

resource "aws_route53_record" "app" {
  count = local.custom_domain_enabled ? 1 : 0

  zone_id = var.hosted_zone_id
  name    = local.app_fqdn
  type    = "A"

  alias {
    name                   = aws_lb.this.dns_name
    zone_id                = aws_lb.this.zone_id
    evaluate_target_health = true
  }

  allow_overwrite = true
}
