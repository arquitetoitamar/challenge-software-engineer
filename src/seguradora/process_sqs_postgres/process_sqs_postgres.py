import json
import boto3
import psycopg2
import os

# Configurações do PostgreSQL
DB_HOST = os.environ['DB_HOST']
DB_NAME = os.environ['DB_NAME']
DB_USER = os.environ['DB_USER']
DB_PASSWORD = os.environ['DB_PASSWORD']

# Conectar ao SQS
sqs = boto3.client("sqs")
QUEUE_URL = os.environ["SQS_QUEUE_URL"]

def lambda_handler(event, context):
    # Conectar ao banco de dados
    conn = psycopg2.connect(
        host=DB_HOST,
        database=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD
    )
    cursor = conn.cursor()

    for record in event["Records"]:
        message_body = json.loads(record["body"])
        proposal_id = message_body["proposal_id"]
        client_name = message_body["data"]["client"]
        proposal_value = message_body["data"]["value"]

        # Inserir dados na tabela de propostas
        sql = "INSERT INTO proposals (proposal_id, client_name, proposal_value) VALUES (%s, %s, %s)"
        cursor.execute(sql, (proposal_id, client_name, proposal_value))
    
    # Confirmar e fechar conexão
    conn.commit()
    cursor.close()
    conn.close()

    return {
        "statusCode": 200,
        "body": json.dumps("Propostas processadas e salvas no PostgreSQL.")
    }
