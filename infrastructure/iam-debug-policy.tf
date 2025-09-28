resource "aws_iam_policy" "debug_s3_dynamo_admin_policy" {
  name        = "${var.project_name}-DebugS3DynamoAdminPolicy"
  description = "DEBUG: Grants full S3 and DynamoDB access to the CI/CD role."

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "s3:*",
        Resource = "*"
      },
      {
        Effect   = "Allow",
        Action   = "dynamodb:*",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "debug_policy_attach" {
  role       = aws_iam_role.github_actions_deployer.name
  policy_arn = aws_iam_policy.debug_s3_dynamo_admin_policy.arn
}