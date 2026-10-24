output "application_url" {
  description = "Public application URL: the custom domain when configured, otherwise the CloudFront domain."
  value       = local.custom_domain_enabled ? "https://${var.domain_name}" : "https://${aws_cloudfront_distribution.this.domain_name}"
}

output "cloudfront_url" {
  description = "CloudFront distribution URL used for cached static assets."
  value       = "https://${aws_cloudfront_distribution.this.domain_name}"
}

output "alb_dns_name" {
  description = "Public DNS name of the Application Load Balancer."
  value       = aws_lb.this.dns_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID."
  value       = aws_cloudfront_distribution.this.id
}

output "vpc_id" {
  description = "VPC ID."
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs used by the ALB and NAT gateways."
  value       = [for subnet in aws_subnet.public : subnet.id]
}

output "private_subnet_ids" {
  description = "Private subnet IDs used by EC2 and RDS."
  value       = [for subnet in aws_subnet.private : subnet.id]
}

output "autoscaling_group_name" {
  description = "Name of the web application Auto Scaling group."
  value       = aws_autoscaling_group.app.name
}

output "rds_endpoint" {
  description = "RDS endpoint. The password is managed by RDS in Secrets Manager."
  value       = aws_db_instance.this.endpoint
}

output "rds_master_secret_arn" {
  description = "ARN of the RDS-managed master user secret."
  value       = aws_db_instance.this.master_user_secret[0].secret_arn
  sensitive   = true
}

output "sns_alarm_topic_arn" {
  description = "SNS topic that receives CloudWatch alarm notifications."
  value       = aws_sns_topic.alarms.arn
}

output "waf_web_acl_arn" {
  description = "ARN of the WAF web ACL attached to the ALB."
  value       = aws_wafv2_web_acl.this.arn
}

output "route53_health_check_id" {
  description = "Route 53 HTTPS health check ID, or null when no custom domain is configured."
  value       = one(aws_route53_health_check.app[*].id)
}
