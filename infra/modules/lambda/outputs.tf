output "process_sqs_postgres_arn" {
  value = aws_lambda_function.process_sqs_postgres.arn
}
output "lambda_exec_role_arn" {
  value = aws_iam_role.lambda_exec.arn
}

output "store_proposal_arn" {
  value = aws_lambda_function.store_proposal.invoke_arn 
}