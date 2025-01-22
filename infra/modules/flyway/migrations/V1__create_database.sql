-- Verifica se o banco já existe, se não, cria
DO $$ 
BEGIN
   IF NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = 'contracts') THEN
      CREATE DATABASE contracts;
   END IF;
END $$;
