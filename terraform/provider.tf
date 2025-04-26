provider "aws" {
  region = var.aws_region
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  backend "s3" {
    # Fill these in or use -backend-config with terraform init
    # bucket = "your-terraform-state-bucket"
    # key    = "aws-nuke-button/terraform.tfstate"
    # region = "us-east-1"
  }
}