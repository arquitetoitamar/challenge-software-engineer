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
resource "random_id" "unique_id" {
  byte_length = 4
}

resource "aws_lambda_function" "store_proposal" {
  function_name = "store-proposal"
  handler       = "store_proposal.lambda_handler"
  runtime       = "python3.9"
  role          = aws_iam_role.lambda_exec.arn
  filename      = "${path.module}/store_proposal.zip"

  source_code_hash = filebase64sha256("${path.module}/store_proposal.zip")  # 🔥 Garante que a Lambda seja atualizada se o ZIP mudar

  environment {
    variables = {
      TABLE_NAME    = var.dynamodb_table_name
      SNS_TOPIC_ARN = var.sns_proposal_arn
    }
  }
}
module "lambda_layer" {
  source = "../lambda_layer"
}
resource "aws_lambda_function" "process_sqs_postgres" {
  function_name = "process-sqs-postgres"
  handler       = "process_sqs_postgres.lambda_handler"
  runtime       = "python3.9"
  role          = aws_iam_role.lambda_exec.arn
  filename      = "${path.module}/process_sqs_postgres.zip"

  source_code_hash = filebase64sha256("${path.module}/process_sqs_postgres.zip")  # 🔥 Garante atualização automática

  # 🔥 Adiciona a camada psycopg2
  layers = [module.lambda_layer.psycopg2_layer_arn]

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

resource "aws_iam_policy" "lambda_dynamodb_policy" {
  name        = "LambdaDynamoDBAccessPolicy"
  description = "Permite que a Lambda armazene dados no DynamoDB"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:Scan"
        ],
        Resource = "arn:aws:dynamodb:us-east-1:615026068056:table/proposals_table"
      }
    ]
  })
}
resource "aws_iam_policy" "lambda_sns_policy" {
  name        = "LambdaSNSPublishPolicy"
  description = "Permite que a Lambda publique mensagens no SNS"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "sns:Publish"
        ],
        Resource = "arn:aws:sns:us-east-1:615026068056:proposal_sns_topic"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_sns_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_sns_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_dynamodb_policy.arn
}

# Permissão para API Gateway invocar a Lambda store_proposal
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowAPIGatewayInvoke-${random_id.unique_id.hex}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.store_proposal.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.api_gateway_execution_arn}/*/*"
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
resource "aws_iam_role_policy_attachment" "lambda_logging" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.store_proposal.function_name}"
  retention_in_days = 30

  lifecycle {
    prevent_destroy = false
    ignore_changes  = [name]
  }
}
