terraform init
terraform validate
terraform plan
terraform apply -auto-approve
curl -X POST "https://abcd1234.execute-api.us-east-1.amazonaws.com/prod/proposals" \
-H "Content-Type: application/json" \
-d '{"proposal_id": "505", "value": 5000, "client": "Gabriela Souza"}'



testar o fluxo enviando uma proposta para a fila SQS.

aws sqs send-message --queue-url https://sqs.us-east-1.amazonaws.com/615026068056/contract-queue \
 --message-body '{"proposal_id": "123", "value": 2000, "client": "João Silva"}'

E verificando se foi armazenada no DynamoDB:
aws dynamodb scan --table-name proposals_table

testando a dlq 

Enviando Mensagem para a Fila Normal
aws sqs send-message --queue-url https://sqs.us-east-1.amazonaws.com/615026068056/contract-queue \
 --message-body '{"proposal_id": "456", "value": 800, "client": "Maria Souza"}'
Verificando a DLQ

aws sqs receive-message --queue-url https://sqs.us-east-1.amazonaws.com/615026068056/contract-dlq

Testando as Permissões SQS
aws iam list-attached-role-policies --role-name lambda-sqs-role

Enviar uma mensagem para a fila SQS
aws sqs send-message --queue-url https://sqs.us-east-1.amazonaws.com/615026068056/contract-queue --message-body '{"proposal_id": "999", "value": 1500, "client": "Ana Pereira"}'

Verificar se a Lambda consegue consumir a mensagem
aws sqs receive-message --queue-url https://sqs.us-east-1.amazonaws.com/615026068056/contract-queue

Testando a API Gateway
Obter a URL da API
terraform output api_gateway_invoke_url
Enviar uma proposta via API
curl -X POST "https://abcd1234.execute-api.us-east-1.amazonaws.com/prod/proposals" \
-H "Content-Type: application/json" \
-d '{"proposal_id": "101", "value": 2000, "client": "Pedro Santos"}'
Verificar o DynamoDB
aws dynamodb scan --table-name proposals_table

Testando a Integração
Obter a URL da API Gateway
terraform output api_gateway_invoke_url
Enviar uma proposta via API
curl -X POST "https://abcd1234.execute-api.us-east-1.amazonaws.com/prod/proposals" \
-H "Content-Type: application/json" \
-d '{"proposal_id": "202", "value": 3000, "client": "Juliana Moreira"}'
Verificar se a mensagem chegou no SNS
aws sns list-subscriptions-by-topic --topic-arn arn:aws:sns:us-east-1:615026068056:proposal_sns_topic

Verificar se a mensagem chegou na fila SQS
aws sqs receive-message --queue-url https://sqs.us-east-1.amazonaws.com/615026068056/contract-queue

teste no postgresql

SELECT * FROM proposals;
