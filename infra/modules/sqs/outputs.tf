output "contract_queue_arn" {
  value = aws_sqs_queue.contract_queue.arn
}

output "contract_queue_url" {
  value = aws_sqs_queue.contract_queue.id
}
output "contract_dlq_name" {
  value = aws_sqs_queue.contract_dlq.name
}
output "status_queue_url" {
  description = "URL da fila SQS para atualização de status"
  value       = aws_sqs_queue.status_queue.url
}
output "status_queue_arn" {
  description = "ARN da fila SQS para atualização de status"
  value       = aws_sqs_queue.status_queue.arn
}