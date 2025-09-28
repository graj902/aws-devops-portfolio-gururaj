terraform {
  backend "s3" {
    bucket         = "gururaj-portfolio-506776019563-tfstate"
    key            = "global/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "gururaj-portfolio-tf-lock"
    encrypt        = true
  }
}