variable "db_host" {
  description = "Endpoint do RDS"
  type        = string
}

variable "db_name" {
  description = "Nome do banco de dados"
  type        = string
}

variable "db_username" {
  description = "Usuário do banco de dados"
  type        = string
}

variable "db_password" {
  description = "Senha do banco de dados"
  type        = string
}

variable "rds_dependency" {
  description = "Dependência para garantir que o RDS seja criado antes de rodar o Flyway"
}
