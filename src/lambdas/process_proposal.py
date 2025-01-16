import json
import boto3
import os

sqs = boto3.client('sqs')
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('proposals_table')

CONTRACT_QUEUE_URL = os.environ['CONTRACT_QUEUE_URL']
STATUS_QUEUE_URL = os.environ['STATUS_QUEUE_URL']
DLQ_URL = os.environ['DLQ_URL']

def lambda_handler(event, context):
    for record in event['Records']:
        message_body = json.loads(record['body'])
        proposal_id = message_body.get("proposal_id")

        print(f"Processing proposal {proposal_id}...")

        try:
            # Simula um processamento
            status = "approved" if message_body["value"] > 1000 else "rejected"

            # Atualiza no DynamoDB
            table.update_item(
                Key={"proposal_id": proposal_id},
                UpdateExpression="set proposal_status = :s",
                ExpressionAttributeValues={":s": status}
            )

            # Envia o status para a fila de status
            sqs.send_message(
                QueueUrl=STATUS_QUEUE_URL,
                MessageBody=json.dumps({"proposal_id": proposal_id, "status": status})
            )

            print(f"Proposal {proposal_id} processed successfully.")

        except Exception as e:
            print(f"Error processing proposal {proposal_id}: {str(e)}")
            
            # Reenvia a mensagem para DLQ após falhas repetidas
            sqs.send_message(
                QueueUrl=DLQ_URL,
                MessageBody=json.dumps(message_body)
            )
            print(f"Proposal {proposal_id} sent to DLQ.")

    return {
        'statusCode': 200,
        'body': json.dumps('Processing complete')
    }
