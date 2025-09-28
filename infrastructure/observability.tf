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
  endpoint  = "gururajrathod101@gmail.com" # <-- YOUR EMAIL ADDRESS
}

# Data source to dynamically find the Application Load Balancer created by the Kubernetes service
/* data "aws_lb" "app_lb" {
  # The ALB name is non-deterministic, so we find it by the tags that EKS automatically applies
  tags = {
    "elbv2.k8s.aws/cluster" = var.project_name
    "service.k8s.aws/name"  = "${var.project_name}-service"
  }

  depends_on = [module.eks] # Ensure this runs after the EKS cluster is available
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
  threshold           = "80" # 80%
  alarm_description   = "This alarm fires when the average CPU utilization of the EKS node group exceeds 80% for 10 minutes."
  
  # Action: Send a notification to our SNS topic
  alarm_actions       = [aws_sns_topic.alarms_topic.arn]

  # Target the specific Auto Scaling Group for our nodes
  dimensions = {
    # FIX: Corrected attribute name from node_group_as_g_name to node_group_asg_name
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
  period              = "60" # 1 minute
  statistic           = "Maximum"
  threshold           = "100" # 100 milliseconds
  alarm_description   = "This alarm fires when the RDS replica lag exceeds 100ms for 3 minutes."
  
  # Action: Send a notification to our SNS topic
  alarm_actions       = [aws_sns_topic.alarms_topic.arn]

  # Target our specific RDS instance
  dimensions = {
    DBInstanceIdentifier = module.rds.db_instance_id
  }
}

# Alarm 3: High rate of 5xx server errors from the Application Load Balancer (Metric Math)
resource "aws_cloudwatch_metric_alarm" "alb_high_5xx_errors" {
  alarm_name          = "${var.project_name}-alb-high-5xx-errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  threshold           = "5" # 5 percent
  alarm_description   = "This alarm fires when the rate of HTTP 5xx errors exceeds 5% over a 5 minute period."

  # Action: Send a notification to our SNS topic
  alarm_actions       = [aws_sns_topic.alarms_topic.arn]

  # Metric Math Expression: (Sum of 5xx Errors / Total Request Count) * 100
  metric_query {
    id          = "e1"
    expression  = "(m1 / m2) * 100"
    label       = "HTTPErrorRatePercent"
    return_data = "true"
  }

  metric_query {
    id = "m1"
    metric {
      metric_name = "HTTPCode_Target_5XX_Count"
      namespace   = "AWS/ApplicationELB"
      period      = "300" # 5 minutes
      stat        = "Sum"
      dimensions = {
        LoadBalancer = data.aws_lb.app_lb.arn_suffix
      }
    }
  }

  metric_query {
    id = "m2"
    metric {
      metric_name = "RequestCount"
      namespace   = "AWS/ApplicationELB"
      period      = "300" # 5 minutes
      stat        = "Sum"
      dimensions = {
        LoadBalancer = data.aws_lb.app_lb.arn_suffix
      }
    }
  }
}
*/