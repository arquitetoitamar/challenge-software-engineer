#!/bin/bash

echo "🔹 Iniciando migração com Flyway..."

# Configuração do Flyway
export FLYWAY_URL="jdbc:postgresql://${1}:5432/postgres"
export FLYWAY_USER="${2}"
export FLYWAY_PASSWORD="${3}"

# Primeiro, cria o banco de dados
echo "🔹 Criando banco contracts se não existir..."
flyway -url=$FLYWAY_URL -user=$FLYWAY_USER -password=$FLYWAY_PASSWORD -locations=filesystem:./migrations -baselineOnMigrate=true migrate

# Agora, conecta-se ao banco `contracts` e aplica as tabelas
export FLYWAY_URL="jdbc:postgresql://${1}:5432/contracts"
echo "🔹 Criando tabelas no banco contracts..."
flyway -url=$FLYWAY_URL -user=$FLYWAY_USER -password=$FLYWAY_PASSWORD -locations=filesystem:./migrations -baselineOnMigrate=true migrate

echo "✅ Migração concluída!"
