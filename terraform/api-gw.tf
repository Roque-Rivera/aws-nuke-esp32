# REST API (v1) instead of HTTP API (v2)
resource "aws_api_gateway_rest_api" "nuke_api" {
  name        = "${var.project_name}-api"
  description = "API for AWS Nuke ESP32"
}

# Resources for our API endpoints
resource "aws_api_gateway_resource" "dry_run" {
  rest_api_id = aws_api_gateway_rest_api.nuke_api.id
  parent_id   = aws_api_gateway_rest_api.nuke_api.root_resource_id
  path_part   = "dry-run"
}

resource "aws_api_gateway_resource" "execute" {
  rest_api_id = aws_api_gateway_rest_api.nuke_api.id
  parent_id   = aws_api_gateway_rest_api.nuke_api.root_resource_id
  path_part   = "execute"
}

# Method for dry-run endpoint
resource "aws_api_gateway_method" "dry_run" {
  rest_api_id   = aws_api_gateway_rest_api.nuke_api.id
  resource_id   = aws_api_gateway_resource.dry_run.id
  http_method   = "POST"
  authorization = "NONE"
  api_key_required = true
}

# Method for execute endpoint
resource "aws_api_gateway_method" "execute" {
  rest_api_id   = aws_api_gateway_rest_api.nuke_api.id
  resource_id   = aws_api_gateway_resource.execute.id
  http_method   = "POST"
  authorization = "NONE"
  api_key_required = true
}

# Integration for dry-run endpoint
resource "aws_api_gateway_integration" "lambda_dry_run" {
  rest_api_id             = aws_api_gateway_rest_api.nuke_api.id
  resource_id             = aws_api_gateway_resource.dry_run.id
  http_method             = aws_api_gateway_method.dry_run.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.nuke_lambda.invoke_arn
}

# Integration for execute endpoint
resource "aws_api_gateway_integration" "lambda_execute" {
  rest_api_id             = aws_api_gateway_rest_api.nuke_api.id
  resource_id             = aws_api_gateway_resource.execute.id
  http_method             = aws_api_gateway_method.execute.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.nuke_lambda.invoke_arn
}

# Method responses
resource "aws_api_gateway_method_response" "dry_run_200" {
  rest_api_id = aws_api_gateway_rest_api.nuke_api.id
  resource_id = aws_api_gateway_resource.dry_run.id
  http_method = aws_api_gateway_method.dry_run.http_method
  status_code = "200"
}

resource "aws_api_gateway_method_response" "execute_200" {
  rest_api_id = aws_api_gateway_rest_api.nuke_api.id
  resource_id = aws_api_gateway_resource.execute.id
  http_method = aws_api_gateway_method.execute.http_method
  status_code = "200"
}

# Integration responses
resource "aws_api_gateway_integration_response" "dry_run" {
  rest_api_id = aws_api_gateway_rest_api.nuke_api.id
  resource_id = aws_api_gateway_resource.dry_run.id
  http_method = aws_api_gateway_method.dry_run.http_method
  status_code = aws_api_gateway_method_response.dry_run_200.status_code
  depends_on  = [aws_api_gateway_integration.lambda_dry_run]
}

resource "aws_api_gateway_integration_response" "execute" {
  rest_api_id = aws_api_gateway_rest_api.nuke_api.id
  resource_id = aws_api_gateway_resource.execute.id
  http_method = aws_api_gateway_method.execute.http_method
  status_code = aws_api_gateway_method_response.execute_200.status_code
  depends_on  = [aws_api_gateway_integration.lambda_execute]
}

# Deployment and stage
resource "aws_api_gateway_deployment" "nuke_api" {
  rest_api_id = aws_api_gateway_rest_api.nuke_api.id
  
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.dry_run.id,
      aws_api_gateway_resource.execute.id,
      aws_api_gateway_method.dry_run.id,
      aws_api_gateway_method.execute.id,
      aws_api_gateway_integration.lambda_dry_run.id,
      aws_api_gateway_integration.lambda_execute.id,
    ]))
  }
  
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "default" {
  deployment_id = aws_api_gateway_deployment.nuke_api.id
  rest_api_id   = aws_api_gateway_rest_api.nuke_api.id
  stage_name    = "default"
}

# API Key for authentication
resource "aws_api_gateway_api_key" "nuke_button_key" {
  name = var.api_key_name
}

# Domain name configuration
resource "aws_api_gateway_domain_name" "api" {
  domain_name     = var.domain_name
  certificate_arn = aws_acm_certificate_validation.cert_validation.certificate_arn
  
  depends_on = [aws_acm_certificate_validation.cert_validation]
}

# Certificate must be in us-east-1 for API Gateway custom domain names
resource "aws_acm_certificate" "api_cert_us_east_1" {
  provider          = aws.us-east-1
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# Certificate validation
resource "aws_acm_certificate_validation" "cert_validation" {
  provider                = aws.us-east-1
  certificate_arn         = aws_acm_certificate.api_cert_us_east_1.arn
  
  # Comment out the validation_record_fqdns line if not using Route53
  # validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
  
  # Using timeouts to allow for DNS propagation
  timeouts {
    create = "60m"
  }
}

# Route53 DNS validation records
# This assumes you are using Route53 for DNS management
resource "aws_route53_record" "cert_validation" {
  provider = aws.us-east-1
  for_each = {
    for dvo in aws_acm_certificate.api_cert_us_east_1.domain_validation_options : dvo.domain_name => dvo
  }

  name    = each.value.resource_record_name
  type    = each.value.resource_record_type
  zone_id = "${var.route53_zone_id}"
  records = [each.value.resource_record_value]
  ttl     = 60
}



# Lambda permissions
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.nuke_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.nuke_api.execution_arn}/*/*"
}

# Create a usage plan for the API key
resource "aws_api_gateway_usage_plan" "nuke_button" {
  name = "${var.project_name}-usage-plan"
  
  api_stages {
    api_id = aws_api_gateway_rest_api.nuke_api.id
    stage  = aws_api_gateway_stage.default.stage_name
  }
}

# Associate the API key with the usage plan
resource "aws_api_gateway_usage_plan_key" "main" {
  key_id        = aws_api_gateway_api_key.nuke_button_key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.nuke_button.id
}