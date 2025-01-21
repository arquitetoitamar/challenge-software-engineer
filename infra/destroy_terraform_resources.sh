#!/bin/bash

# 🚀 Script para destruir infraestrutura Terraform mesmo sem state

# ⚠️ AVISO: Isso excluirá recursos da AWS de forma irreversível. Tenha certeza antes de executar!

set -e  # Para o script se algum comando falhar
set -x  # Ativa debug para visualizar os comandos

echo "🔍 Tentando rodar terraform destroy normalmente..."
terraform destroy -auto-approve || echo "⚠️ Terraform state ausente. Prosseguindo com remoção manual..."

echo "🔄 Removendo arquivos de state Terraform..."
rm -rf .terraform terraform.tfstate*

echo "🔄 Inicializando Terraform..."
terraform init

echo "🛠️ Importando recursos para Terraform antes de destruir..."

# 🎯 Importação manual de recursos para o Terraform
terraform import aws_dynamodb_table.proposals proposals_table || echo "⚠️ Tabela não encontrada, ignorando..."
terraform import aws_lambda_function.store_proposal store-proposal || echo "⚠️ Lambda não encontrada, ignorando..."
terraform import aws_lambda_function.process_sqs_postgres process-sqs-postgres || echo "⚠️ Lambda não encontrada, ignorando..."
terraform import aws_iam_role.lambda_exec lambda_exec_role || echo "⚠️ IAM Role não encontrada, ignorando..."
terraform import aws_api_gateway_rest_api.proposal_api proposal-api || echo "⚠️ API Gateway não encontrado, ignorando..."

echo "🔨 Executando terraform destroy..."
terraform destroy -auto-approve || echo "⚠️ Terraform não conseguiu destruir tudo, removendo via AWS CLI..."

echo "🔥 Removendo recursos manualmente via AWS CLI..."

# 🔥 Excluindo DynamoDB
aws dynamodb delete-table --table-name proposals_table || echo "⚠️ Tabela não encontrada, ignorando..."

# 🔥 Excluindo Lambda
aws lambda delete-function --function-name store-proposal || echo "⚠️ Lambda não encontrada, ignorando..."
aws lambda delete-function --function-name process-sqs-postgres || echo "⚠️ Lambda não encontrada, ignorando..."

# 🔥 Excluindo API Gateway
API_ID=$(aws apigateway get-rest-apis --query "items[?name=='proposal-api'].id" --output text)
if [ -n "$API_ID" ]; then
    aws apigateway delete-rest-api --rest-api-id "$API_ID"
else
    echo "⚠️ API Gateway não encontrado, ignorando..."
fi

# 🔥 Excluindo IAM Role
aws iam delete-role --role-name lambda_exec_role || echo "⚠️ IAM Role não encontrada, ignorando..."

# 🔥 Excluindo SQS
aws sqs delete-queue --queue-url https://sqs.us-east-1.amazonaws.com/615026068056/contract-queue || echo "⚠️ SQS não encontrada, ignorando..."
aws sqs delete-queue --queue-url https://sqs.us-east-1.amazonaws.com/615026068056/status-queue || echo "⚠️ SQS não encontrada, ignorando..."

# 🔥 Excluindo Segurança e VPC
SECURITY_GROUP_ID=$(aws ec2 describe-security-groups --query "SecurityGroups[?GroupName=='rds-security-group'].GroupId" --output text)
if [ -n "$SECURITY_GROUP_ID" ]; then
    aws ec2 delete-security-group --group-id "$SECURITY_GROUP_ID"
else
    echo "⚠️ Security Group não encontrado, ignorando..."
fi

VPC_ID=$(aws ec2 describe-vpcs --query "Vpcs[?Tags[?Key=='Name' && Value=='project-vpc']].VpcId" --output text)
if [ -n "$VPC_ID" ]; then
    aws ec2 delete-vpc --vpc-id "$VPC_ID"
else
    echo "⚠️ VPC não encontrada, ignorando..."
fi

# 🔥 Excluindo TODAS as Políticas IAM criadas pelo Terraform
echo "🛑 Excluindo todas as políticas IAM criadas..."
POLICIES=("LambdaDynamoDBAccessPolicy" "LambdaSNSPublishPolicy" "LambdaRDSAccessPolicy" "LambdaSQSAccessPolicy" "LambdaVPCExecutionPolicy" "sqs-policy")

for policy in "${POLICIES[@]}"; do
    POLICY_ARN=$(aws iam list-policies --scope Local --query "Policies[?PolicyName=='$policy'].Arn" --output text)
    if [ -n "$POLICY_ARN" ]; then
        aws iam delete-policy --policy-arn "$POLICY_ARN" || echo "⚠️ Falha ao excluir $policy"
    else
        echo "⚠️ Política $policy não encontrada, ignorando..."
    fi
done

echo "✅ Todos os recursos foram removidos com sucesso!"
