# Testes da Infraestrutura AWS com Terraform

## Inicialização do Terraform
```sh
terraform init
terraform validate
terraform plan
terraform apply -auto-approve
```

## Testando a API Gateway
### Enviar uma proposta via API
```sh
curl -X POST "https://abcd1234.execute-api.us-east-1.amazonaws.com/prod/proposals" -H "Content-Type: application/json" -d '{"proposal_id": "505", "value": 5000, "client": "Gabriela Souza"}'
```

## Testando o Fluxo de Mensagens para a Fila SQS
### Enviar uma proposta para a fila SQS
```sh
aws sqs send-message --queue-url https://sqs.us-east-1.amazonaws.com/615026068056/contract-queue  --message-body '{"proposal_id": "123", "value": 2000, "client": "João Silva"}'
```

### Verificando se foi armazenada no DynamoDB
```sh
aws dynamodb scan --table-name proposals_table
```

## Testando a DLQ (Dead Letter Queue)
### Enviando Mensagem para a Fila Normal
```sh
aws sqs send-message --queue-url https://sqs.us-east-1.amazonaws.com/615026068056/contract-queue  --message-body '{"proposal_id": "456", "value": 800, "client": "Maria Souza"}'
```
### Verificando a DLQ
```sh
aws sqs receive-message --queue-url https://sqs.us-east-1.amazonaws.com/615026068056/contract-dlq
```

## Testando as Permissões SQS
```sh
aws iam list-attached-role-policies --role-name lambda-sqs-role
```

### Enviar uma mensagem para a fila SQS
```sh
aws sqs send-message --queue-url https://sqs.us-east-1.amazonaws.com/615026068056/contract-queue --message-body '{"proposal_id": "999", "value": 1500, "client": "Ana Pereira"}'
```

### Verificar se a Lambda consegue consumir a mensagem
```sh
aws sqs receive-message --queue-url https://sqs.us-east-1.amazonaws.com/615026068056/contract-queue
```

## Testando a API Gateway
### Obter a URL da API
```sh
terraform output api_gateway_invoke_url
```

### Enviar uma proposta via API
```sh
curl -X POST "https://abcd1234.execute-api.us-east-1.amazonaws.com/prod/proposals" -H "Content-Type: application/json" -d '{"proposal_id": "101", "value": 2000, "client": "Pedro Santos"}'
```

### Verificar o DynamoDB
```sh
aws dynamodb scan --table-name proposals_table
```

## Testando a Integração
### Obter a URL da API Gateway
```sh
terraform output api_gateway_invoke_url
```

### Enviar uma proposta via API
```sh
curl -X POST "https://abcd1234.execute-api.us-east-1.amazonaws.com/prod/proposals" -H "Content-Type: application/json" -d '{"proposal_id": "202", "value": 3000, "client": "Juliana Moreira"}'
```

### Verificar se a mensagem chegou no SNS
```sh
aws sns list-subscriptions-by-topic --topic-arn arn:aws:sns:us-east-1:615026068056:proposal_sns_topic
```

### Verificar se a mensagem chegou na fila SQS
```sh
aws sqs receive-message --queue-url https://sqs.us-east-1.amazonaws.com/615026068056/contract-queue
```

## Teste no PostgreSQL
```sql
SELECT * FROM proposals;
```
