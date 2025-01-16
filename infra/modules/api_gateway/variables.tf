variable "lambda_proposal_arn" {
  description = "ARN da função Lambda que será chamada pelo API Gateway"
  type        = string
}

variable "function_name" {
  description = "Name da função Lambda que será chamada pelo API Gateway"
  type        = string
}