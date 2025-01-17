output "api_gateway_invoke_url" {
  value = "${aws_api_gateway_deployment.deployment.invoke_url}/proposals"
}

resource "aws_api_gateway_deployment" "deployment" {
  depends_on  = [aws_api_gateway_integration.post_proposal_lambda]
  rest_api_id = aws_api_gateway_rest_api.proposal_api.id
}
output "execution_arn" {
  description = "ARN de execução do API Gateway"
  value       = aws_api_gateway_rest_api.proposal_api.execution_arn
}
