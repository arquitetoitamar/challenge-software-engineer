variable "db_username" {
  description = "Usuário do banco de dados"
  type        = string
}

variable "db_password" {
  description = "Senha do banco de dados"
  type        = string
  sensitive   = true
}

variable "subnet_ids" {
  description = "Lista de subnets para o RDS"
  type        = list(string)
}
variable "security_group_ids" {
  description = "Lista de Security Groups para o RDS"
  type        = list(string)
}
