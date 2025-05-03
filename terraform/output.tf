output "api_endpoint" {
  description = "API Gateway endpoint URL"
  value       = "https://${aws_api_gateway_rest_api.nuke_api.id}.execute-api.${var.aws_region}.amazonaws.com/${aws_api_gateway_stage.default.stage_name}"
}

output "api_key" {
  description = "API Key to use in the ESP32 device"
  value       = aws_api_gateway_api_key.nuke_button_key.value
  sensitive   = true
}

# Output validation details - you'll need to manually add these to your DNS provider
output "certificate_validation_details" {
  value = {
    for dvo in aws_acm_certificate.api_cert_us_east_1.domain_validation_options : dvo.domain_name => {
      name    = dvo.resource_record_name
      record  = dvo.resource_record_value
      type    = dvo.resource_record_type
    }
  }
  description = "The DNS records required for certificate validation. Add these to your DNS provider."
}