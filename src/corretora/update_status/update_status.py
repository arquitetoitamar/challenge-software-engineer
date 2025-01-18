import json
import boto3
import os
import logging

# Configuração do logger
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger()

# Configurações do DynamoDB e SQS a partir de variáveis de ambiente
DYNAMODB_TABLE = os.getenv("DYNAMODB_TABLE_NAME")
QUEUE_URL = os.getenv("STATUS_QUEUE_URL")

# Conectar ao DynamoDB
dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(DYNAMODB_TABLE)


def lambda_handler(event, context):
    """Função Lambda para atualizar o status de propostas no DynamoDB a partir da fila SQS."""

    if not DYNAMODB_TABLE or not QUEUE_URL:
        logger.error("Erro de configuração: Variáveis de ambiente ausentes")
        return {
            "statusCode": 500,
            "body": json.dumps({"status": "Config_Error", "error": "Variáveis de ambiente ausentes"})
        }

    try:
        for record in event.get("Records", []):
            try:
                # 🔥 Garantir que `record["body"]` seja uma string antes de carregar JSON
                message_body = record["body"]
                if isinstance(message_body, dict):
                    data = message_body  # Já é um dicionário
                else:
                    data = json.loads(message_body)  # Converter string JSON para dicionário

                # Validar campos
                proposal_id = data.get("proposal_id")
                proposal_status = data.get("proposal_status")

                if not proposal_id or not proposal_status:
                    raise ValueError("Campos obrigatórios ausentes na mensagem")

                # 🔥 Atualizar status no DynamoDB
                response = table.update_item(
                    Key={"proposal_id": proposal_id},  # 🔥 Verifique se "proposal_id" é chave primária no DynamoDB
                    UpdateExpression="SET proposal_status = :status",
                    ExpressionAttributeValues={":status": proposal_status},
                    ReturnValues="UPDATED_NEW"
                )

                logger.info(f"✅ Status da proposta {proposal_id} atualizado para {proposal_status}.")
                logger.info(f"Resposta do DynamoDB: {response}")

            except json.JSONDecodeError as e:
                logger.error(f"❌ Erro ao decodificar JSON da mensagem: {str(e)}")
            except KeyError as e:
                logger.error(f"❌ Chave ausente na mensagem: {str(e)}")
            except ValueError as e:
                logger.error(f"❌ Erro de validação da mensagem: {str(e)}")
            except Exception as e:
                logger.error(f"❌ Erro inesperado ao processar mensagem: {str(e)}")

    except Exception as e:
        logger.error(f"❌ Erro ao processar mensagens do SQS: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps({"status": "Processing_Error", "error": str(e)})
        }

    return {
        "statusCode": 200,
        "body": json.dumps({"status": "Success", "message": "Propostas atualizadas no DynamoDB."})
    }