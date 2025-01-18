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
TABLE_NAME = os.environ.get("TABLE_NAME")
SNS_TOPIC_ARN = os.environ.get("SNS_TOPIC_ARN")
table = dynamodb.Table(TABLE_NAME)

def lambda_handler(event, context):
    responses = []

    try:
        # O corpo da requisição vem no campo "body" no API Gateway
        body = event.get("body", "{}")

        # Se o body for uma string JSON, converte para dicionário
        if isinstance(body, str):
            message_body = json.loads(body)
        else:
            message_body = body  # Já é um dicionário

        proposal_id = str(uuid.uuid4())
        timestamp = int(time.time())

        item = {
            "proposal_id": proposal_id,
            "created_at": timestamp,
            "data": message_body
        }

        # ✅ Salvar no DynamoDB com tratamento de erro
        try:
            table.put_item(Item=item)
            logger.info(f"✅ Proposta {proposal_id} armazenada no DynamoDB.")
        except Exception as e:
            logger.error(f"❌ Erro ao salvar no DynamoDB: {str(e)}")
            return {
                "statusCode": 500,
                "body": json.dumps({"status": "DynamoDB_Error", "error": str(e)})
            }

        # ✅ Publicar no SNS com tratamento de erro
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
                "proposal_id": proposal_id
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
