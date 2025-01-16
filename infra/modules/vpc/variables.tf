variable "vpc_cidr" {
  description = "CIDR da VPC"
  type        = string
}

variable "public_subnet_1_cidr" {
  description = "CIDR da Subnet Pública 1"
  type        = string
}

variable "public_subnet_2_cidr" {
  description = "CIDR da Subnet Pública 2"
  type        = string
}

variable "private_subnet_1_cidr" {
  description = "CIDR da Subnet Privada 1"
  type        = string
}

variable "private_subnet_2_cidr" {
  description = "CIDR da Subnet Privada 2"
  type        = string
}

variable "az1" {
  description = "Zona de Disponibilidade 1"
  type        = string
}

variable "az2" {
  description = "Zona de Disponibilidade 2"
  type        = string
}

variable "allowed_ip" {
  description = "IP permitido para acessar o banco de dados"
  type        = string
}
