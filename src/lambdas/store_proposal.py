import json
import boto3
import os
import uuid
import time

dynamodb = boto3.resource("dynamodb")
sns = boto3.client("sns")

TABLE_NAME = os.environ["TABLE_NAME"]
SNS_TOPIC_ARN = os.environ["SNS_TOPIC_ARN"]
table = dynamodb.Table(TABLE_NAME)

def lambda_handler(event, context):
    for record in event["Records"]:
        message_body = json.loads(record["body"])
        proposal_id = str(uuid.uuid4())
        timestamp = int(time.time())

        item = {
            "proposal_id": proposal_id,
            "created_at": timestamp,
            "data": message_body
        }

        # Salvar no DynamoDB
        table.put_item(Item=item)
        print(f"Proposta {proposal_id} armazenada no DynamoDB.")

        # Publicar no SNS para processar a proposta via SQS
        sns.publish(
            TopicArn=SNS_TOPIC_ARN,
            Message=json.dumps(item)
        )
        print(f"Proposta {proposal_id} enviada para SNS.")

    return {
        "statusCode": 200,
        "body": json.dumps("Propostas armazenadas e enviadas para SNS.")
    }
