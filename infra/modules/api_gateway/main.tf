resource "aws_api_gateway_rest_api" "proposal_api" {
  name        = "proposal-api"
  description = "API Gateway para gerenciar propostas"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}
resource "random_id" "unique_id" {
  byte_length = 4
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

# 🔹 Correção na integração da API Gateway com a Lambda
resource "aws_api_gateway_integration" "post_proposal_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.proposal_api.id
  resource_id             = aws_api_gateway_resource.proposals.id
  http_method             = aws_api_gateway_method.post_proposal.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${var.lambda_proposal_arn}/invocations" 
}

# 🔹 Adicionando um `Deployment` para o estágio funcionar corretamente
resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.proposal_api.id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.proposal_api))
  }

  lifecycle {
    create_before_destroy = true  # Garante que o deploy não quebre entre atualizações
  }

  depends_on = [aws_api_gateway_integration.post_proposal_lambda]
}

# 🔹 Configuração do estágio "dev"
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
    ignore_changes = [deployment_id]
  }
}

# 🔹 Logs do API Gateway
resource "aws_cloudwatch_log_group" "apigateway_logs" {
  name              = "/aws/apigateway/proposal-api"
  retention_in_days = 30

  tags = {
    Environment = "production"
    Service     = "API Gateway"
  }

  lifecycle {
    prevent_destroy = false
    ignore_changes  = [name]
  }
}

# 🔹 Permissão para API Gateway invocar a Lambda `store_proposal`
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowAPIGatewayInvoke-${random_id.unique_id.hex}"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_proposal_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.proposal_api.execution_arn}/*/*"
}

# 🔹 Permissão para API Gateway usar o X-Ray
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
