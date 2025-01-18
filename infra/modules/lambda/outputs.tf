output "process_sqs_postgres_arn" {
  description = "ARN da função Lambda que processa mensagens do SQS e insere no PostgreSQL"
  value       = aws_lambda_function.process_sqs_postgres.arn
}
output "lambda_exec_role_arn" {
  value = aws_iam_role.lambda_exec.arn
}
output "store_proposal_arn" {
  value = aws_lambda_function.store_proposal.invoke_arn 
}
output "store_proposal_function_name" {
  value = aws_lambda_function.store_proposal.function_name
}
