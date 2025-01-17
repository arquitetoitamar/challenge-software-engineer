import json
import boto3
import psycopg2
import os
import logging

# Configuração do logger
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger()

# Configurações do PostgreSQL a partir de variáveis de ambiente
DB_HOST = os.getenv('DB_HOST')
DB_NAME = os.getenv('DB_NAME')
DB_USER = os.getenv('DB_USER')
DB_PASSWORD = os.getenv('DB_PASSWORD')

# Conectar ao SQS
sqs = boto3.client("sqs")
QUEUE_URL = os.getenv("SQS_QUEUE_URL")


def lambda_handler(event, context):
    """Função Lambda para processar mensagens do SQS e armazená-las no PostgreSQL."""
    
    if not DB_HOST or not DB_NAME or not DB_USER or not DB_PASSWORD or not QUEUE_URL:
        logger.error("Erro de configuração: Variáveis de ambiente ausentes")
        return {
            "statusCode": 500,
            "body": json.dumps({"status": "Config_Error", "error": "Variáveis de ambiente ausentes"})
        }

    try:
        # Conectar ao banco de dados PostgreSQL
        conn = psycopg2.connect(
            host=DB_HOST,
            database=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD
        )
        cursor = conn.cursor()
        logger.info("Conexão com o PostgreSQL estabelecida.")

    except Exception as e:
        logger.error(f"Erro ao conectar ao banco de dados: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps({"status": "DB_Connection_Error", "error": str(e)})
        }

    try:
        # Processar mensagens do SQS
        for record in event.get("Records", []):
            try:
                message_body = json.loads(record["body"])
                
                # Validação dos campos necessários
                proposal_id = message_body.get("proposal_id")
                client_name = message_body.get("data", {}).get("client")
                proposal_value = message_body.get("data", {}).get("value")

                if not proposal_id or not client_name or not proposal_value:
                    raise ValueError("Campos obrigatórios ausentes na mensagem")

                # Inserir dados na tabela de propostas
                sql = "INSERT INTO proposals (proposal_id, client_name, proposal_value) VALUES (%s, %s, %s)"
                cursor.execute(sql, (proposal_id, client_name, proposal_value))
                logger.info(f"Proposta {proposal_id} inserida com sucesso.")

            except json.JSONDecodeError as e:
                logger.error(f"Erro ao decodificar JSON da mensagem: {str(e)}")
            except KeyError as e:
                logger.error(f"Chave ausente na mensagem: {str(e)}")
            except ValueError as e:
                logger.error(f"Erro de validação da mensagem: {str(e)}")
            except Exception as e:
                logger.error(f"Erro inesperado ao processar mensagem: {str(e)}")

        # Confirmar as alterações no banco
        conn.commit()

    except Exception as e:
        logger.error(f"Erro ao processar mensagens do SQS: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps({"status": "Processing_Error", "error": str(e)})
        }

    finally:
        # Fechar conexão com o banco de dados
        if conn:
            cursor.close()
            conn.close()
            logger.info("Conexão com o PostgreSQL encerrada.")

    return {
        "statusCode": 200,
        "body": json.dumps({"status": "Success", "message": "Propostas processadas e salvas no PostgreSQL."})
    }
