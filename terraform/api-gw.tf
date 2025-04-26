resource "aws_apigatewayv2_api" "nuke_api" {
  name          = "${var.project_name}-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.nuke_api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_apigatewayv2_integration" "lambda_dry_run" {
  api_id                 = aws_apigatewayv2_api.nuke_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.nuke_lambda.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "lambda_execute" {
  api_id                 = aws_apigatewayv2_api.nuke_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.nuke_lambda.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "dry_run" {
  api_id    = aws_apigatewayv2_api.nuke_api.id
  route_key = "POST /dry-run"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_dry_run.id}"
  
  authorization_type = "API_KEY"
}

resource "aws_apigatewayv2_route" "execute" {
  api_id    = aws_apigatewayv2_api.nuke_api.id
  route_key = "POST /execute"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_execute.id}"
  
  authorization_type = "API_KEY"
}

# API Key for authentication
resource "aws_api_gateway_api_key" "nuke_button_key" {
  name = var.api_key_name
}

resource "aws_apigatewayv2_api_mapping" "example" {
  api_id      = aws_apigatewayv2_api.nuke_api.id
  domain_name = aws_apigatewayv2_domain_name.api.id
  stage       = aws_apigatewayv2_stage.default.id
}

resource "aws_apigatewayv2_domain_name" "api" {
  domain_name = "nuke-button-api.example.com"  # Change this to your domain

  domain_name_configuration {
    certificate_arn = aws_acm_certificate.api.arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}

# You'll need to create or import an ACM certificate for your domain
resource "aws_acm_certificate" "api" {
  domain_name       = "nuke-button-api.example.com"  # Change this to your domain
  validation_method = "DNS"
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.nuke_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.nuke_api.execution_arn}/*/*"
}

# Create a usage plan for the API key
resource "aws_api_gateway_usage_plan" "nuke_button" {
  name        = "${var.project_name}-usage-plan"
  
  api_stages {
    api_id = aws_apigatewayv2_api.nuke_api.id
    stage  = aws_apigatewayv2_stage.default.name
  }
}

# Associate the API key with the usage plan
resource "aws_api_gateway_usage_plan_key" "main" {
  key_id        = aws_api_gateway_api_key.nuke_button_key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.nuke_button.id
}