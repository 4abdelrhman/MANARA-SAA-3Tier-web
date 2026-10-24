data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_launch_template" "app" {
  name        = "${local.name}-lt"
  description = "Amazon Linux 2023 web application instances"
  image_id    = data.aws_ssm_parameter.al2023.value

  instance_type          = var.instance_type
  update_default_version = true

  iam_instance_profile {
    arn = aws_iam_instance_profile.app.arn
  }

  vpc_security_group_ids = [aws_security_group.app.id]

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  monitoring {
    enabled = true
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = 20
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  user_data = base64encode(templatefile("${path.module}/templates/user_data.sh.tftpl", {
    cloudfront_base_url = "https://${aws_cloudfront_distribution.this.domain_name}"
  }))

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${local.name}-app"
    }
  }

  tag_specifications {
    resource_type = "volume"

    tags = {
      Name = "${local.name}-app-volume"
    }
  }

  tags = {
    Name = "${local.name}-lt"
  }
}

resource "aws_autoscaling_group" "app" {
  name                      = "${local.name}-asg"
  min_size                  = var.asg_min_size
  max_size                  = var.asg_max_size
  desired_capacity          = var.asg_desired_capacity
  vpc_zone_identifier       = [for subnet in aws_subnet.private : subnet.id]
  target_group_arns         = [aws_lb_target_group.app.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"

    preferences {
      min_healthy_percentage = 50
      instance_warmup        = 300
    }
  }

  dynamic "tag" {
    for_each = merge(
      local.common_tags,
      {
        Name = "${local.name}-app"
      }
    )

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    ignore_changes = [desired_capacity]
  }

  depends_on = [aws_lb_listener.http]
}

resource "aws_autoscaling_policy" "cpu_target_tracking" {
  name                   = "${local.name}-cpu-target-tracking"
  autoscaling_group_name = aws_autoscaling_group.app.name
  policy_type            = "TargetTrackingScaling"

  estimated_instance_warmup = 300

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 50
  }
}

resource "aws_autoscaling_policy" "cpu_step_scale_out" {
  name                    = "${local.name}-cpu-step-scale-out"
  autoscaling_group_name  = aws_autoscaling_group.app.name
  policy_type             = "StepScaling"
  adjustment_type         = "ChangeInCapacity"
  metric_aggregation_type = "Average"
  cooldown                = 300

  estimated_instance_warmup = 300

  step_adjustment {
    metric_interval_lower_bound = 0
    scaling_adjustment          = 2
  }
}

resource "aws_cloudwatch_metric_alarm" "asg_step_scale_out" {
  alarm_name          = "${local.name}-asg-step-scale-out"
  alarm_description   = "Adds two instances when average ASG CPU remains at or above 70 percent."
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 3
  datapoints_to_alarm = 2
  threshold           = 70
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }

  alarm_actions = [aws_autoscaling_policy.cpu_step_scale_out.arn]
}
