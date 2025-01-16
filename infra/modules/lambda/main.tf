resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}


resource "aws_lambda_function" "store_proposal" {
  function_name = "store-proposal"
  handler       = "store_proposal.lambda_handler"
  runtime       = "python3.9"
  role          = aws_iam_role.lambda_exec.arn
  filename      = "${path.module}/store_proposal.zip"

  environment {
    variables = {
      TABLE_NAME    = var.dynamodb_table_name
      SNS_TOPIC_ARN = var.sns_proposal_arn
    }
  }
}

resource "aws_lambda_function" "process_sqs_postgres" {
  function_name = "process-sqs-postgres"
  handler       = "process_sqs_postgres.lambda_handler"
  runtime       = "python3.9"
  role          = aws_iam_role.lambda_exec.arn
  filename      = "${path.module}/process_sqs_postgres.zip"

  environment {
    variables = {
      DB_HOST       = var.db_host
      DB_NAME       = var.db_name
      DB_USER       = var.db_user
      DB_PASSWORD   = var.db_password
      SQS_QUEUE_URL = var.sqs_contract_queue_url
    }
  }
}

# Permissão para API Gateway invocar a Lambda store_proposal
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.store_proposal.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${var.api_gateway_execution_arn}/*/*"
}

# Configuração para que a Lambda process_sqs_postgres leia mensagens da SQS
resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = var.sqs_contract_queue_arn
  function_name    = aws_lambda_function.process_sqs_postgres.arn
  batch_size       = 10

  # Correção: evita recriação se o mapeamento já existir
  depends_on = [aws_lambda_function.process_sqs_postgres]
}

resource "aws_iam_policy" "lambda_sqs_policy" {
  name        = "LambdaSQSAccessPolicy"
  description = "Permissões para a Lambda ler mensagens do SQS"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ],
        Resource = var.sqs_contract_queue_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_sqs_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_sqs_policy.arn
}
