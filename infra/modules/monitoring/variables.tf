variable "contract_dlq_name" {
  description = "Nome da fila DLQ de contratos"
  type        = string
}
variable "sns_proposal_arn" {
  description = "ARN do SNS para alertas do CloudWatch"
  type        = string
}
