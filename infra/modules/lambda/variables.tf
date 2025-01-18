variable "dynamodb_table_name" {
  description = "Nome da tabela DynamoDB para armazenar propostas"
  type        = string
}

variable "sns_proposal_arn" {
  description = "ARN do SNS para publicar propostas"
  type        = string
}

variable "sqs_contract_queue_url" {
  description = "URL da fila SQS de contratação"
  type        = string
}

variable "sqs_contract_queue_arn" {
  description = "ARN da fila SQS de contratação"
  type        = string
}

variable "api_gateway_execution_arn" {
  description = "ARN de execução do API Gateway"
  type        = string
}

variable "db_host" {
  description = "Host do banco PostgreSQL"
  type        = string
}

variable "db_name" {
  description = "Nome do banco PostgreSQL"
  type        = string
}

variable "db_user" {
  description = "Usuário do banco PostgreSQL"
  type        = string
}

variable "db_password" {
  description = "Senha do banco PostgreSQL"
  type        = string
  sensitive   = true
}

variable "sqs_status_queue_url" {
  description = "URL da fila SQS para atualização de status"
  type        = string
}

variable "sqs_status_queue_arn" {
  description = "ARN da fila SQS para atualização de status"
  type        = string
}