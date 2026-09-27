resource "aws_cloudwatch_metric_alarm" "monitor_alarm" {
  alarm_name          = "alb-unhealthy-targets"
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Minimum"
  threshold           = 0
  evaluation_periods  = 2
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  dimensions = {
    TargetGroup  = aws_lb_target_group.target_group.arn_suffix
    LoadBalancer = aws_alb.main_alb.arn_suffix
  }

  insufficient_data_actions = []
  alarm_actions             = [aws_sns_topic.sns_topic.arn]
}

resource "aws_sns_topic" "sns_topic" {
  name = "sns-topic-cloudwatch"

}

resource "aws_sns_topic_subscription" "sns_subscription" {
  topic_arn = aws_sns_topic.sns_topic.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

variable "alert_email" {
  type        = string
  description = "Email address used for alerts"
}

resource "aws_autoscaling_policy" "cpu_scaling" {
  name                      = "cpu-scaling-test"
  autoscaling_group_name    = aws_autoscaling_group.main_asg.name
  policy_type               = "TargetTrackingScaling"
  estimated_instance_warmup = 300

  target_tracking_configuration {
    target_value = 50

    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
  }
}