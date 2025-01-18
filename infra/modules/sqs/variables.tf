variable "contract_queue_arn" {
  description = "ARN da fila SQS de contratação"
  type        = string
}
variable "contract_queue_url" {
  description = "URL da fila SQS para envio de mensagens"
  type        = string
}
variable "process_sqs_postgres_arn" {
  description = "ARN da função Lambda que processa a fila SQS e insere no PostgreSQL"
  type        = string
}
