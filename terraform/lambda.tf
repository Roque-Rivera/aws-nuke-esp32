resource "aws_s3_bucket" "nuke_config" {
  bucket = "${var.project_name}-config-${random_string.suffix.result}"
  
  tags = {
    Name = "${var.project_name}-config"
  }
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_object" "nuke_config_file" {
  bucket  = aws_s3_bucket.nuke_config.id
  key     = "nuke-config.yml"
  source = "${path.module}/nuke-config.yml"
}

resource "aws_lambda_function" "nuke_lambda" {
  function_name = "${var.project_name}-lambda"
  
  # Using a container image
  package_type = "Image"
  image_uri    = "${aws_ecr_repository.nuke_container.repository_url}:latest"
  
  role = aws_iam_role.lambda_role.arn
  
  timeout     = 900  # 15 minutes, maximum allowed
  memory_size = 1024
  
  vpc_config {
    subnet_ids         = [aws_subnet.public.id]
    security_group_ids = [aws_security_group.lambda.id]
  }
  
  environment {
    variables = {
      CONFIG_BUCKET = aws_s3_bucket.nuke_config.id
      CONFIG_KEY    = aws_s3_object.nuke_config_file.key
      TARGET_ACCOUNT = var.aws_account_id
    }
  }
}

resource "aws_ecr_repository" "nuke_container" {
  name = "${var.project_name}-repo"
  
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.nuke_lambda.function_name}"
  retention_in_days = 14
}