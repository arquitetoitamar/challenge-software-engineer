resource "aws_sqs_queue" "contract_dlq" {
  name                      = "contract-dlq"
  message_retention_seconds = 1209600 # 14 dias
}

resource "aws_sqs_queue" "contract_queue" {
  name                      = "contract-queue"
  message_retention_seconds = 86400
  visibility_timeout_seconds = 30
  receive_wait_time_seconds  = 5

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.contract_dlq.arn
    maxReceiveCount     = 5  # Mensagem falha 5 vezes antes de ir para DLQ
  })
}

resource "aws_sqs_queue" "status_dlq" {
  name                      = "status-dlq"
  message_retention_seconds = 1209600 # 14 dias
}

resource "aws_sqs_queue" "status_queue" {
  name                      = "status-queue"
  message_retention_seconds = 86400
  visibility_timeout_seconds = 30
  receive_wait_time_seconds  = 5

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.status_dlq.arn
    maxReceiveCount     = 5  # Mensagem falha 5 vezes antes de ir para DLQ
  })
}

resource "aws_iam_policy" "sqs_policy" {
  name        = "sqs-policy"
  description = "Permissões para acessar filas SQS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = [
          aws_sqs_queue.contract_queue.arn,
          aws_sqs_queue.contract_dlq.arn,
          aws_sqs_queue.status_queue.arn,
          aws_sqs_queue.status_dlq.arn
        ]
      }
    ]
  })
}
