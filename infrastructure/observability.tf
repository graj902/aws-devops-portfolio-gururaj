# --- Phase 1: Logging Infrastructure ---

# IAM Policy to allow EKS nodes to write logs to CloudWatch
resource "aws_iam_policy" "eks_node_cloudwatch_logs_policy" {
  name        = "${var.project_name}-EKSNodeCloudWatchLogsPolicy"
  description = "Allows EKS nodes to push logs to CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ],
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Attach the policy to the EKS Node Role created in the EKS module
resource "aws_iam_role_policy_attachment" "eks_node_cloudwatch_logs_attach" {
  role       = module.eks.node_role_name
  policy_arn = aws_iam_policy.eks_node_cloudwatch_logs_policy.arn
}

# --- Phase 2: Alerting Infrastructure ---

# SNS Topic that all alarms will notify
resource "aws_sns_topic" "alarms_topic" {
  name = "${var.project_name}-alarms-topic"
}

# Subscription to the topic, sending notifications to an email address
resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.alarms_topic.arn
  protocol  = "email"
  endpoint  = "gururajrathod101@gmail.com" # Your email address
}

# Data source to find the Classic Load Balancer created by the Kubernetes service.
data "aws_elb" "app_elb" {
  name = "a237895c55c814c80bf85d88edeca9fa" # <-- PASTE THE NAME FROM THE AWS CONSOLE HERE
}


# Alarm 1: High CPU utilization on the EKS nodes' Auto Scaling Group
resource "aws_cloudwatch_metric_alarm" "eks_nodes_high_cpu" {
  alarm_name          = "${var.project_name}-eks-nodes-high-cpu"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300" # 5 minutes
  statistic           = "Average"
  threshold           = "80"  # 80%
  alarm_description   = "This alarm fires when the average CPU utilization of the EKS node group exceeds 80% for 10 minutes."
  alarm_actions       = [aws_sns_topic.alarms_topic.arn]

  dimensions = {
    # This now correctly references the output from the EKS module
    AutoScalingGroupName = module.eks.node_group_asg_name
  }
}

# Alarm 2: RDS Replica Lag
resource "aws_cloudwatch_metric_alarm" "rds_replica_lag" {
  alarm_name          = "${var.project_name}-rds-replica-lag"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "3"
  metric_name         = "ReplicaLag"
  namespace           = "AWS/RDS"
  period              = "60"  # 1 minute
  statistic           = "Maximum"
  threshold           = "100" # 100 milliseconds
  alarm_description   = "This alarm fires when the RDS replica lag exceeds 100ms for 3 minutes."
  alarm_actions       = [aws_sns_topic.alarms_topic.arn]

  dimensions = {
    DBInstanceIdentifier = module.rds.db_instance_id
  }
}

# Alarm 3: High rate of 5xx server errors from the Classic Load Balancer (Metric Math)
resource "aws_cloudwatch_metric_alarm" "elb_high_5xx_errors" {
  alarm_name          = "${var.project_name}-elb-high-5xx-errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  threshold           = "5" # 5 percent
  alarm_description   = "This alarm fires when the rate of HTTP 5xx errors exceeds 5% over a 5 minute period."
  alarm_actions       = [aws_sns_topic.alarms_topic.arn]

  metric_query {
    id          = "e1"
    expression  = "(m1 / m2) * 100"
    label       = "HTTPErrorRatePercent"
    return_data = "true"
  }

  metric_query {
    id = "m1"
    metric {
      metric_name = "HTTPCode_Backend_5XX"
      namespace   = "AWS/ELB"
      period      = "300"
      stat        = "Sum"
      dimensions = {
        LoadBalancerName = data.aws_elb.app_elb.name
      }
    }
  }

  metric_query {
    id = "m2"
    metric {
      metric_name = "RequestCount"
      namespace   = "AWS/ELB"
      period      = "300"
      stat        = "Sum"
      dimensions = {
        LoadBalancerName = data.aws_elb.app_elb.name
      }
    }
  }
}
# --- Phase 3: Visualization ---

# CloudWatch Dashboard to visualize key system metrics
resource "aws_cloudwatch_dashboard" "main_dashboard" {
  dashboard_name = "${var.project_name}-MainDashboard"

  # The dashboard body is a JSON object defining the widgets and their layout
  dashboard_body = jsonencode({
    widgets = [
      # Widget 1: EKS Node CPU Utilization
      {
        type   = "metric",
        x      = 0,
        y      = 0,
        width  = 12,
        height = 6,
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", module.eks.node_group_asg_name]
          ],
          period = 300,
          stat   = "Average",
          region = var.aws_region,
          title  = "EKS Nodes CPU Utilization (%)"
        }
      },
      # Widget 2: RDS Replica Lag
      {
        type   = "metric",
        x      = 12,
        y      = 0,
        width  = 12,
        height = 6,
        properties = {
          metrics = [
            ["AWS/RDS", "ReplicaLag", "DBInstanceIdentifier", module.rds.db_instance_id]
          ],
          period = 60,
          stat   = "Maximum",
          region = var.aws_region,
          title  = "RDS Replica Lag (ms)"
        }
      },
      # Widget 3: Load Balancer Request Count & 5xx Errors
      {
        type   = "metric",
        x      = 0,
        y      = 7,
        width  = 24, # Make this widget full-width
        height = 6,
        properties = {
          metrics = [
            ["AWS/ELB", "HTTPCode_Backend_5XX", "LoadBalancerName", data.aws_elb.app_elb.name, { "label" = "5xx Errors" }],
            [".", "RequestCount", ".", ".", { "label" = "Total Requests", "yAxis": "right" }]
          ],
          yAxis = {
            left = {
              min = 0,
              label = "5xx Count"
            },
            right = {
              min = 0,
              label = "Request Count"
            }
          },
          period = 300,
          stat   = "Sum",
          region = var.aws_region,
          title  = "Classic Load Balancer: Requests & 5xx Errors"
        }
      }
    ]
  })
}