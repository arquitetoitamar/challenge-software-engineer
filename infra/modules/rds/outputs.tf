output "db_host" {
  value = aws_db_instance.postgresql.address
}

output "rds_endpoint" {
  value = aws_db_instance.postgresql.address
}
