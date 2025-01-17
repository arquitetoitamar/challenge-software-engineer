resource "aws_api_gateway_rest_api" "proposal_api" {
  name        = "proposal-api"
  description = "API Gateway para gerenciar propostas"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# Recurso /proposals
resource "aws_api_gateway_resource" "proposals" {
  rest_api_id = aws_api_gateway_rest_api.proposal_api.id
  parent_id   = aws_api_gateway_rest_api.proposal_api.root_resource_id
  path_part   = "proposals"
}

# Método POST para enviar propostas
resource "aws_api_gateway_method" "post_proposal" {
  rest_api_id   = aws_api_gateway_rest_api.proposal_api.id
  resource_id   = aws_api_gateway_resource.proposals.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "random_id" "unique_id" {
  byte_length = 4
}

# Implantação da API Gateway
resource "aws_api_gateway_integration" "post_proposal_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.proposal_api.id
  resource_id             = aws_api_gateway_resource.proposals.id
  http_method             = aws_api_gateway_method.post_proposal.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${var.lambda_proposal_arn}/invocations"

}
resource "aws_cloudwatch_log_group" "apigateway_logs" {
  name              = "/aws/apigateway/proposal-api"
  retention_in_days = 30

  tags = {
    Environment = "production"
    Service     = "API Gateway"
  }

  lifecycle {
    prevent_destroy = false  # 🔥 Evita erro ao tentar recriar um log group já existente
    ignore_changes  = [name]  # 🔥 Ignora conflitos caso o nome já exista
  }
}
resource "aws_api_gateway_stage" "dev" {
  stage_name    = "dev"
  rest_api_id   = aws_api_gateway_rest_api.proposal_api.id
  deployment_id = aws_api_gateway_deployment.deployment.id

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.apigateway_logs.arn
    format = jsonencode({
      requestId       = "$context.requestId"
      extendedRequestId = "$context.extendedRequestId"
      ip              = "$context.identity.sourceIp"
      requestTime     = "$context.requestTime"
      httpMethod      = "$context.httpMethod"
      resourcePath    = "$context.resourcePath"
      status          = "$context.status"
      responseLength  = "$context.responseLength"
      integrationErrorMessage = "$context.integration.error"
      integrationStatus = "$context.integration.status"
      integrationLatency = "$context.integration.latency"
    })
  }

  lifecycle {
    ignore_changes = [deployment_id]  # 🔥 Ignora mudanças na `deployment_id`, evitando conflitos
  }
}

resource "aws_iam_role" "apigateway_xray_role" {
  name = "APIGatewayXRayRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "apigateway.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "apigateway_xray" {
  name       = "APIGatewayXRayPolicyAttachment"
  roles      = [aws_iam_role.apigateway_xray_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess"
}
