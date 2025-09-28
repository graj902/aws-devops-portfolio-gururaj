variable "project_name" {
  description = "The name of the project, used for tagging."
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC to deploy the ElastiCache cluster into."
  type        = string
}

variable "private_subnet_ids" {
  description = "A list of private subnet IDs for the ElastiCache cluster."
  type        = list(string)
}

variable "cluster_security_group_id" {
  description = "The security group ID of the EKS cluster, to allow ingress."
  type        = string
}