# /infrastructure/outputs.tf

output "ecr_repository_url" {
  description = "The URL of the ECR repository for the application images."
  value       = module.ecr.repository_url
}

output "eks_cluster_name" {
  description = "The name of the EKS cluster."
  value       = module.eks.cluster_name
}

output "aws_region" {
  description = "The AWS region where the infrastructure is deployed."
  value       = var.aws_region
}

output "github_deployer_role_arn" {
  description = "The ARN of the IAM role for GitHub Actions to assume."
  value       = aws_iam_role.github_actions_deployer.arn
}