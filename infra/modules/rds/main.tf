resource "aws_db_instance" "postgresql" {
  identifier           = "contract-db"
  allocated_storage    = 20
  engine              = "postgres"
  engine_version      = "14"
  instance_class      = "db.t3.micro"
  username           = var.db_username
  password           = var.db_password
  db_subnet_group_name = aws_db_subnet_group.main.name
  vpc_security_group_ids = var.security_group_ids 
  publicly_accessible = true
  skip_final_snapshot = true
}

resource "aws_db_subnet_group" "main" {
  name       = "rds-subnet-group"
  subnet_ids = var.subnet_ids
}

resource "aws_security_group" "rds_sg" {
  name        = "rds-security-group"
  description = "Permitir acesso ao PostgreSQL"
  
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Ajuste conforme necessário
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

