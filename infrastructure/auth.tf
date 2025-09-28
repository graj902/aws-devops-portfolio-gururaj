resource "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/managed-by" = "Terraform"
    }
  }

  data = {
    mapRoles = yamlencode([
      {
        rolearn  = module.eks.node_role_arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups = [
          "system:bootstrappers",
          "system:nodes",
        ]
      },
    ])
    # --- ADD THIS ENTIRE mapUsers BLOCK ---
    mapUsers = yamlencode([
      {
        userarn  = aws_iam_role.github_actions_deployer.arn
        username = "github-actions-deployer"
        groups = [
          "system:masters" # Granting admin privileges to the deployer role
        ]
      }
    ])
    # --- END of mapUsers BLOCK ---
  }

  depends_on = [
    module.eks,
    aws_iam_role.github_actions_deployer
  ]
}