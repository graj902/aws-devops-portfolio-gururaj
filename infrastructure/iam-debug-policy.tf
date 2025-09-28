resource "aws_iam_policy" "debug_pipeline_permissions" {
  name        = "${var.project_name}-DebugPipelinePermissions"
  description = "DEBUG: Grants all necessary permissions for the CI/CD pipeline."

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # Full S3 and DynamoDB access for Terraform state
      {
        Effect   = "Allow",
        Action   = "s3:*",
        Resource = "*"
      },
      {
        Effect   = "Allow",
        Action   = "dynamodb:*",
        Resource = "*"
      },
      # ECR login permission
      {
        Effect   = "Allow",
        Action   = "ecr:GetAuthorizationToken",
        Resource = "*"
      },
      # EKS describe permission for provider configuration
      {
        Effect   = "Allow",
        Action   = "eks:DescribeCluster",
        Resource = module.eks.cluster_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "debug_policy_attach" {
  role       = aws_iam_role.github_actions_deployer.name
  policy_arn = aws_iam_policy.debug_pipeline_permissions.arn
}