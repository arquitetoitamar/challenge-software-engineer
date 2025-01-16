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

# Permitir que API Gateway invoque a Lambda
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowAPIGatewayInvoke-${random_id.unique_id.hex}"  # ID único
  action        = "lambda:InvokeFunction"
  function_name = var.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.proposal_api.execution_arn}/*/*"
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
