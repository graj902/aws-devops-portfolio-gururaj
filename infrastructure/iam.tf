data "aws_caller_identity" "current" {}

# This data source gets the OIDC provider certificate from GitHub
data "tls_certificate" "github_oidc" {
  url = "https://token.actions.githubusercontent.com"
}

# This resource creates the trust relationship between your AWS account and GitHub Actions
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github_oidc.certificates[0].sha1_fingerprint]
}

# This is the trust policy document for the deployer role
data "aws_iam_policy_document" "github_actions_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    # This condition ensures that only workflows from your specific repository can assume this role
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["graj902/aws-devops-portfolio-gururaj:*"]
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
        Resource = module.eks.cluster_arn # This output will be added to the EKS module next
      },
      {
        Action   = "ecr:GetAuthorizationToken",
        Effect   = "Allow",
        Resource = "*" # This action does not support resource-level permissions
      }
    ]
  })
}

# Attach the permissions policy to the deployer role
resource "aws_iam_role_policy_attachment" "deployer_policy_attach" {
  role       = aws_iam_role.github_actions_deployer.name
  policy_arn = aws_iam_policy.github_actions_deployer_policy.arn
}