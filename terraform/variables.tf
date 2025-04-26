variable "aws_region" {
  description = "The AWS region to deploy to"
  type        = string
  default     = "eu-wesst-3"
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

variable "aws_nuke_config" {
  description = "The aws-nuke configuration content"
  type        = string
}

variable "api_key_name" {
  description = "Name for the API key"
  type        = string
  default     = "esp32-nuke-button-key"
}