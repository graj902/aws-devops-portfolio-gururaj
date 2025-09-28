variable "project_name" {
  description = "The name of the project, used for tagging."
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC to deploy the RDS instance into."
  type        = string
}

variable "private_subnet_ids" {
  description = "A list of private subnet IDs for the RDS instance."
  type        = list(string)
}

variable "cluster_security_group_id" {
  description = "The security group ID of the EKS cluster, to allow ingress."
  type        = string
}

variable "db_username" {
  description = "The master username for the database."
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "The master password for the database."
  type        = string
  sensitive   = true
}