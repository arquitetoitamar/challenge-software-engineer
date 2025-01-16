# Criando o tópico SNS
resource "aws_sns_topic" "proposal_sns_topic" {
  name = "proposal_sns_topic"
}

# Criando a assinatura do SNS para enviar mensagens para a SQS de contratação
resource "aws_sns_topic_subscription" "sqs_subscription" {
  topic_arn = aws_sns_topic.proposal_sns_topic.arn
  protocol  = "sqs"
  endpoint  = var.contract_sqs_arn
}

# Permissão para que SNS publique mensagens na SQS
resource "aws_sqs_queue_policy" "sns_to_sqs_policy" {
  queue_url = var.contract_sqs_url

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = "*"
        Action    = "SQS:SendMessage"
        Resource  = var.contract_sqs_arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.proposal_sns_topic.arn
          }
        }
      }
    ]
  })
}
