-- Criar o banco de dados se não existir
DO $$ 
BEGIN
   IF NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = 'contracts') THEN
      CREATE DATABASE contracts;
   END IF;
END $$;

-- Conectar ao banco de dados contracts (essa parte pode variar conforme o cliente SQL que você está usando)
\c contracts;

-- Criar a tabela proposals se não existir
CREATE TABLE IF NOT EXISTS proposals (
    id SERIAL PRIMARY KEY,
    proposal_id UUID NOT NULL,
    client_name VARCHAR(255) NOT NULL,
    proposal_value DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
