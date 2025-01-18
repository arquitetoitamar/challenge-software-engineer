import json
import boto3
import os
import uuid
import time
import logging

# Configuração do logger
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Inicialização dos clientes AWS
dynamodb = boto3.resource("dynamodb")
sns = boto3.client("sns")

# Carregar variáveis de ambiente
TABLE_NAME = os.getenv("TABLE_NAME")
SNS_TOPIC_ARN = os.getenv("SNS_TOPIC_ARN")

if not TABLE_NAME or not SNS_TOPIC_ARN:
    raise ValueError("❌ Erro de configuração: TABLE_NAME ou SNS_TOPIC_ARN não definidos.")

table = dynamodb.Table(TABLE_NAME)


def lambda_handler(event, context):
    """Processa requisições do API Gateway, armazena propostas no DynamoDB e publica no SNS."""

    logger.info("📩 Evento recebido: %s", json.dumps(event))

    try:
        # Valida se há um corpo de requisição
        body = event.get("body", "{}")
        if not body:
            return {
                "statusCode": 400,
                "body": json.dumps({"status": "Error", "message": "Corpo da requisição vazio."})
            }

        # Se o body for uma string JSON, converte para dicionário
        message_body = json.loads(body) if isinstance(body, str) else body

        # Criar um UUID único para a proposta
        proposal_id = str(uuid.uuid4())
        timestamp = int(time.time())

        # Estrutura do item para o DynamoDB
        item = {
            "proposal_id": proposal_id,
            "created_at": timestamp,
            "data": message_body
        }

        # ✅ Salvar no DynamoDB
        try:
            table.put_item(Item=item)
            logger.info(f"✅ Proposta {proposal_id} armazenada no DynamoDB.")
        except Exception as e:
            logger.error(f"❌ Erro ao salvar no DynamoDB: {str(e)}")
            return {
                "statusCode": 500,
                "body": json.dumps({"status": "DynamoDB_Error", "error": str(e)})
            }

        # ✅ Publicar no SNS
        try:
            sns.publish(
                TopicArn=SNS_TOPIC_ARN,
                Message=json.dumps(item)
            )
            logger.info(f"✅ Proposta {proposal_id} enviada para SNS.")
        except Exception as e:
            logger.error(f"❌ Erro ao publicar no SNS: {str(e)}")
            return {
                "statusCode": 500,
                "body": json.dumps({"status": "SNS_Error", "error": str(e)})
            }

        return {
            "statusCode": 200,
            "body": json.dumps({
                "status": "Success",
                "proposal_id": proposal_id,
                "created_at": timestamp,
                "message": "Proposta criada com sucesso!"
            })
        }

    except json.JSONDecodeError as e:
        logger.error(f"❌ Erro ao decodificar JSON: {str(e)}")
        return {
            "statusCode": 400,
            "body": json.dumps({"status": "JSON_Decode_Error", "error": str(e)})
        }

    except Exception as e:
        logger.critical(f"🔥 Erro crítico na execução da Lambda: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps({"status": "Lambda_Failure", "error": str(e)})
        }
