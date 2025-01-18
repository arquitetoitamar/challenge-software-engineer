# **🚀 Guia de Implantação - Infraestrutura AWS com Terraform**

Este documento fornece um guia detalhado para a implantação da infraestrutura AWS usando **Terraform**, incluindo a configuração de **VPC, RDS, SQS, SNS, API Gateway e funções Lambda**.

---
### **Infraestrutura**
![Solução TO BE 1](../assets/infra.PNG)
## **📌 Pré-requisitos**
Antes de começar, certifique-se de que possui os seguintes itens instalados:

- [Terraform](https://developer.hashicorp.com/terraform/downloads)
- [AWS CLI](https://aws.amazon.com/cli/)
- [Python 3.9+](https://www.python.org/downloads/)
- [Zip](https://linux.die.net/man/1/zip) (para compactação das funções Lambda)

### **💡 Configuração da AWS CLI**
Antes de rodar o Terraform, configure suas credenciais AWS executando:
```bash
aws configure
```
Insira:
- **AWS Access Key ID**
- **AWS Secret Access Key**
- **Região** (exemplo: `us-east-1`)

---

## **📂 Estrutura do Projeto**
```bash
project/
│── infra/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── modules/
│       ├── vpc/
│       ├── rds/
│       ├── sqs/
│       ├── sns/
│       ├── lambda/
│       ├── api_gateway/
│       ├── dynamodb/
│       ├── monitoring/
│── src/
│   ├── lambdas/
│       ├── store_proposal.py
│       ├── process_sqs_postgres.py
│── README.md
│── build.sh
```

---

## **1️⃣ Criando o Pacote ZIP das Funções Lambda**
Antes de executar o Terraform, crie os arquivos **ZIP** das funções Lambda.

### **📌 Automatizando com `build.sh`**
O script abaixo compacta automaticamente os arquivos das funções Lambda.

**1️⃣ Crie o arquivo `build.sh` na raiz do projeto:**
```bash
#!/bin/bash

echo "📦 Empacotando funções Lambda..."

LAMBDA_SRC_DIR="src/lambdas"
LAMBDA_DIST_DIR="modules/lambda"

# Verifica se o comando zip está instalado
if ! command -v zip &> /dev/null; then
  echo "❌ O comando 'zip' não foi encontrado. Instale o zip antes de continuar."
  exit 1
fi

# Criando pacotes ZIP para cada Lambda
for FUNCTION in store_proposal process_sqs_postgres; do
  echo "🔹 Compactando $FUNCTION..."
  zip -j "$LAMBDA_DIST_DIR/$FUNCTION.zip" "$LAMBDA_SRC_DIR/$FUNCTION.py"
done

echo "✅ Todas as funções foram empacotadas com sucesso!"
```

**2️⃣ Conceda permissão de execução ao script:**
```bash
chmod +x build.sh
```

**3️⃣ Execute o script antes do Terraform:**
```bash
./build.sh
```

---

## **2️⃣ Executando o Terraform**
Agora, inicialize e aplique o Terraform para provisionar a infraestrutura.

### **📌 Inicializar o Terraform**
```bash
terraform init
```

### **📌 Validar a configuração**
```bash
terraform validate
```

### **📌 Visualizar o plano antes da aplicação**
```bash
terraform plan
```

### **📌 Aplicar as configurações**
```bash
terraform apply -auto-approve
```

Isso criará todos os recursos da AWS, incluindo **VPC, RDS, API Gateway, SNS, SQS e Lambdas**.

---

## **3️⃣ Testando a API e o SQS**

### **📌 Enviar uma solicitação para o API Gateway**
```bash
curl -X POST "https://SEU_API_GATEWAY_URL/proposals" -H "Content-Type: application/json" -d '{"proposal_id": "123", "value": 5000, "client": "João Silva"}'
```

### **📌 Verificar se a mensagem chegou na SQS**
```bash
aws sqs receive-message --queue-url https://sqs.us-east-1.amazonaws.com/123456789012/contract-queue
```

### **📌 Verificar se a Lambda processou a mensagem e inseriu no PostgreSQL**
```sql
SELECT * FROM proposals;
```

---

## **📌 Conclusão**
✅ **Infraestrutura AWS implantada com Terraform**  
✅ **Funções Lambda empacotadas corretamente**  
✅ **Mensagens fluindo corretamente do API Gateway → SNS → SQS → Lambda → PostgreSQL**  

Agora sua infraestrutura está pronta para uso! 🚀

Se precisar de mais ajustes, entre em contato! 😊
