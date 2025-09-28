module "vpc" {
  source = "./modules/vpc"

  project_name       = var.project_name
  availability_zones = ["ap-south-1a", "ap-south-1b"]
}

module "eks" {
  source = "./modules/eks"

  cluster_name       = var.project_name
  project_name       = var.project_name
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
}

module "rds" {
  source = "./modules/rds"

  project_name              = var.project_name
  vpc_id                    = module.vpc.vpc_id
  private_subnet_ids        = module.vpc.private_subnet_ids
  cluster_security_group_id = module.eks.cluster_security_group_id # This will be added in the next step
  db_username               = var.db_username
  db_password               = var.db_password

  depends_on = [module.eks]
}

module "elasticache" {
  source = "./modules/elasticache"

  project_name              = var.project_name
  vpc_id                    = module.vpc.vpc_id
  private_subnet_ids        = module.vpc.private_subnet_ids
  cluster_security_group_id = module.eks.cluster_security_group_id # This will be added in the next step

  depends_on = [module.eks]
}

module "ecr" {
  source = "./modules/ecr"

  repository_name = var.project_name # Use the project name for the ECR repo
}