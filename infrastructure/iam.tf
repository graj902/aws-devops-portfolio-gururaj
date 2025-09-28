data "aws_caller_identity" "current" {}

# This data source looks up the OIDC provider that already exists in the AWS account.
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

# This is the trust policy document for the deployer role
data "aws_iam_policy_document" "github_actions_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn] # This line now correctly uses the ARN from the data source
    }

    # This condition ensures that only workflows from your specific repository can assume this role
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:graj902/aws-devops-portfolio-gururaj:*"] # Corrected the value to include "repo:"
    }
  }
}

# This is the IAM role that the GitHub Actions workflow will assume to deploy
resource "aws_iam_role" "github_actions_deployer" {
  name               = "${var.project_name}-github-deployer-role"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role_policy.json
  description        = "IAM role for the portfolio project CI/CD pipeline"
}

# This is the permissions policy for the deployer role
resource "aws_iam_policy" "github_actions_deployer_policy" {
  name        = "${var.project_name}-GitHubDeployerPolicy"
  description = "Permissions for the GitHub Actions deployer role"
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = "eks:DescribeCluster",
        Effect   = "Allow",
        Resource = module.eks.cluster_arn
      },
      {
        Action   = "ecr:GetAuthorizationToken",
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}

# Attach the permissions policy to the deployer role
resource "aws_iam_role_policy_attachment" "deployer_policy_attach" {
  role       = aws_iam_role.github_actions_deployer.name
  policy_arn = aws_iam_policy.github_actions_deployer_policy.arn
}