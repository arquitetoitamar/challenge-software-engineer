output "api_gateway_invoke_url" {
  value = "${aws_api_gateway_deployment.deployment.invoke_url}/proposals"
}

output "execution_arn" {
  description = "ARN de execução do API Gateway"
  value       = aws_api_gateway_rest_api.proposal_api.execution_arn
}
