output "contract_queue_arn" {
  value = aws_sqs_queue.contract_queue.arn
}

output "contract_queue_url" {
  value = aws_sqs_queue.contract_queue.id
}
output "contract_dlq_name" {
  value = aws_sqs_queue.contract_dlq.name
}
