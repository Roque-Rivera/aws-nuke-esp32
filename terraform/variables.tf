variable "aws_region" {
  description = "The AWS region to deploy to"
  type        = string
  default     = "eu-west-3"
}

variable "project_name" {
  description = "The name of the project"
  type        = string
  default     = "aws-nuke-button"
}

variable "aws_account_id" {
  description = "The AWS account ID to nuke resources from"
  type        = string
}


variable "api_key_name" {
  description = "Name for the API key"
  type        = string
  default     = "esp32-nuke-button-key"
}

variable "domain_name" {
  description = "The domain name for the API Gateway"
  type        = string
  default     = "example.com"  # Change this to your domain
  
}

variable "route53_zone_id" {
  description = "The Route53 zone ID for the domain"
  type        = string
}