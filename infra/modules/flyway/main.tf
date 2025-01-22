resource "null_resource" "wait_for_rds" {
  provisioner "local-exec" {
    command = <<EOT
      echo "⏳ Aguardando RDS ficar pronto..."
      until nc -z ${var.db_host} 5432; do sleep 5; done
      echo "✅ RDS está pronto!"
    EOT
  }

  triggers = {
    always_run = timestamp()
  }

  depends_on = [var.rds_dependency]  # Garante que o RDS esteja criado antes
}

resource "null_resource" "flyway_migration" {
  provisioner "local-exec" {
    command = <<EOT
      echo "📥 Baixando e instalando Flyway..."
      wget -qO- https://repo1.maven.org/maven2/org/flywaydb/flyway-commandline/9.22.3/flyway-commandline-9.22.3-linux-x64.tar.gz | tar xvz
      export PATH=$PWD/flyway-9.22.3:$PATH

      echo "🛠 Criando banco 'contracts' se não existir..."
      PGPASSWORD="${var.db_password}" psql -h ${var.db_host} -U ${var.db_username} -d postgres -c "CREATE DATABASE contracts;" || true

      echo "🚀 Executando migrações Flyway..."
      flyway -url="jdbc:postgresql://${var.db_host}:5432/contracts" -user="${var.db_username}" -password="${var.db_password}" -locations=filesystem:modules/flyway/migrations migrate
    EOT
  }

  triggers = {
    always_run = timestamp()  # Força a execução sempre que Terraform rodar
  }

  depends_on = [null_resource.wait_for_rds]
}
