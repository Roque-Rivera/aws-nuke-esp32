provider "aws" {
  region = var.aws_region
}

provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
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
    bucket = "aws-nuke-button"
    key    = "aws-nuke-button/terraform.tfstate"
    region = "eu-west-1"
  }
}