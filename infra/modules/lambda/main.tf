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

# 🚀 Lambda store_proposal (Criação de propostas)
resource "aws_lambda_function" "store_proposal" {
  function_name = "store-proposal"
  handler       = "store_proposal.lambda_handler"
  runtime       = "python3.9"
  role          = aws_iam_role.lambda_exec.arn
  filename      = "${path.module}/store_proposal.zip"

  source_code_hash = filebase64sha256("${path.module}/store_proposal.zip")

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

# 🚀 Lambda process_sqs_postgres (Processar Propostas e enviar para status_queue)
resource "aws_lambda_function" "process_sqs_postgres" {
  function_name = "process-sqs-postgres"
  handler       = "process_sqs_postgres.lambda_handler"
  runtime       = "python3.9"
  role          = aws_iam_role.lambda_exec.arn
  filename      = "${path.module}/process_sqs_postgres.zip"

  source_code_hash = filebase64sha256("${path.module}/process_sqs_postgres.zip")

  layers = [module.lambda_layer.psycopg2_layer_arn]

  vpc_config {
    subnet_ids         = var.private_subnet_ids  # ✅ Corrigido para usar a variável
    security_group_ids = [var.lambda_security_group_id]  # ✅ Corrigido para usar a variável
  }
  environment {
    variables = {
      DB_HOST       = var.db_host
      DB_NAME       = var.db_name
      DB_USER       = var.db_user
      DB_PASSWORD   = var.db_password
      SQS_QUEUE_URL = var.sqs_contract_queue_url
      STATUS_QUEUE_URL = var.sqs_status_queue_url
    }
  }
}

# 🚀 Nova Lambda update_status (Atualizar status no DynamoDB)
resource "aws_lambda_function" "update_status" {
  function_name = "update-status"
  handler       = "update_status.lambda_handler"
  runtime       = "python3.9"
  role          = aws_iam_role.lambda_exec.arn
  filename      = "${path.module}/update_status.zip"

  source_code_hash = filebase64sha256("${path.module}/update_status.zip")

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = var.dynamodb_table_name
      STATUS_QUEUE_URL = var.sqs_status_queue_url
    }
  }
}

# 🛠️ Políticas IAM
## Permissão para gravar no RDS
resource "aws_security_group_rule" "allow_lambda_rds" {
  type              = "ingress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  security_group_id = var.rds_security_group_id  # ✅ Agora passa a variável
  source_security_group_id = var.lambda_security_group_id  # ✅ Corrigido para usar variável
}
## Permissão para gravar no DynamoDB
resource "aws_iam_policy" "lambda_dynamodb_policy" {
  name        = "LambdaDynamoDBAccessPolicy"
  description = "Permite que a Lambda armazene e atualize dados no DynamoDB"

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

## Permissão para publicar no SNS
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

## Permissão para acessar PostgreSQL no RDS
resource "aws_iam_policy" "lambda_rds_policy" {
  name        = "LambdaRDSAccessPolicy"
  description = "Permite que a Lambda acesse o RDS PostgreSQL"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "rds:DescribeDBInstances",
          "rds:Connect",
          "rds:DescribeDBClusters"
        ],
        Resource = "arn:aws:rds:us-east-1:615026068056:db:contract-db"
      }
    ]
  })
}

## Permissão para ler filas SQS
resource "aws_iam_policy" "lambda_sqs_send_status_policy" {
  name        = "LambdaSQSSendStatusPolicy"
  description = "Permite que a Lambda process_sqs_postgres envie mensagens para a fila de status"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "sqs:SendMessage"
        ],
        Resource = var.sqs_status_queue_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_sqs_send_status_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_sqs_send_status_policy.arn
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
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ],
        Resource = [
          var.sqs_contract_queue_arn,
          var.sqs_status_queue_arn
        ]
      }
    ]
  })
}
resource "aws_iam_policy" "lambda_vpc_access" {
  name        = "LambdaVPCExecutionPolicy"
  description = "Permite que a Lambda crie interfaces de rede na VPC"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# 🛠️ security gorups


# 🛠️ Anexar permissões às Lambdas
resource "aws_iam_role_policy_attachment" "lambda_vpc_access_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_vpc_access.arn
}

resource "aws_iam_role_policy_attachment" "lambda_rds_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_rds_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_sns_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_sns_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_dynamodb_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_sqs_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_sqs_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_logging" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# 🛠️ Conectar Lambdas às filas SQS
resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = var.sqs_contract_queue_arn
  function_name    = aws_lambda_function.process_sqs_postgres.arn
  batch_size       = 10
}

resource "aws_lambda_event_source_mapping" "status_sqs_trigger" {
  event_source_arn = var.sqs_status_queue_arn
  function_name    = aws_lambda_function.update_status.arn
  batch_size       = 10
}

# 📌 Configuração para API Gateway chamar a Lambda store_proposal
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowAPIGatewayInvoke-${random_id.unique_id.hex}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.store_proposal.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.api_gateway_execution_arn}/*/*"
}

# 🚀 Criar logs para monitoramento
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.store_proposal.function_name}"
  retention_in_days = 30
}
