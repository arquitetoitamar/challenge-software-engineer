variable "contract_queue_arn" {
  description = "ARN da fila SQS de contratação"
  type        = string
}

variable "process_sqs_postgres_arn" {
  description = "ARN da Lambda que processa a SQS"
  type        = string
}
