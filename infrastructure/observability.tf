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