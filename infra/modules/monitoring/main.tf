resource "aws_cloudwatch_metric_alarm" "dlq_alarm" {
  alarm_name          = "DLQMessageCountAlarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "Alerta para mensagens na DLQ"
  alarm_actions       = [var.sns_proposal_arn]  # Correção: Usar variável em vez de recurso inexistente
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
resource "aws_iam_role" "apigateway_cloudwatch_role" {
  name = "APIGatewayCloudWatchRole"

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

resource "aws_iam_policy_attachment" "apigateway_cloudwatch" {
  name       = "APIGatewayCloudWatchPolicyAttachment"
  roles      = [aws_iam_role.apigateway_cloudwatch_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}


