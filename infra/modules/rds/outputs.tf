output "db_host" {
  value = aws_db_instance.postgresql.address
}

output "rds_endpoint" {
  value = aws_db_instance.postgresql.address
}
output "rds_connection_url" {
  description = "URL de conexão ao PostgreSQL"
  value       = "postgresql://${var.db_username}:${var.db_password}@${aws_db_instance.postgresql.endpoint}:5432/contracts"
  sensitive   = true  # Oculta o valor na saída do Terraform para segurança
}