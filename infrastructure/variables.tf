variable "project_name" {
  description = "The unique name for this project, used for naming and tagging resources."
  type        = string
  default     = "gururaj-portfolio"
}

variable "aws_region" {
  description = "The AWS region to deploy all resources into."
  type        = string
  default     = "ap-south-1"
}

variable "db_username" {
  description = "The master username for the RDS database."
  type        = string
  default     = "dbadmin"
  sensitive   = true
}

variable "db_password" {
  description = "The master password for the RDS database. Must meet complexity requirements."
  type        = string
  default     = "MustBeAComplexPassword1!"
  sensitive   = true
}