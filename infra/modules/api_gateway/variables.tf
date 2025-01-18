variable "lambda_proposal_function_name" {
  description = "Name da função Lambda que será chamada pelo API Gateway"
  type        = string
}

variable "lambda_proposal_arn" {
  description = "ARN da função Lambda que o API Gateway deve invocar"
  type        = string
}

variable "aws_region" {
  description = "Região da AWS"
  type        = string
}
