#!/bin/bash

echo "📦 Iniciando a compactação das funções Lambda..."

# Diretório onde estão os arquivos das funções Lambda
LAMBDA_SRC_DIR="src/lambdas"

# Verifica se o diretório existe
if [ ! -d "$LAMBDA_SRC_DIR" ]; then
  echo "❌ Diretório $LAMBDA_SRC_DIR não encontrado! Verifique o caminho."
  exit 1
fi

# Verifica se o comando zip está instalado
if ! command -v zip &> /dev/null; then
  echo "❌ O comando 'zip' não foi encontrado. Instale o zip antes de continuar."
  exit 1
fi

# Criando pacotes ZIP para cada Lambda individualmente
for FUNCTION in store_proposal process_sqs_postgres; do
  echo "🔹 Compactando $FUNCTION..."
  
  if [ -f "$LAMBDA_SRC_DIR/$FUNCTION.py" ]; then
    zip -j "$FUNCTION.zip" "$LAMBDA_SRC_DIR/$FUNCTION.py"
  else
    echo "⚠️ Aviso: Arquivo $LAMBDA_SRC_DIR/$FUNCTION.py não encontrado, pulando..."
  fi
done

echo "✅ Todas as funções foram empacotadas com sucesso!"
