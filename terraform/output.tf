output "api_endpoint" {
  description = "API Gateway endpoint URL"
  value       = aws_apigatewayv2_stage.default.invoke_url
}

output "api_key" {
  description = "API Key to use in the ESP32 device"
  value       = aws_api_gateway_api_key.nuke_button_key.value
  sensitive   = true
}