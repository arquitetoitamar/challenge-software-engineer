provider "aws" {
  region = "us-east-1"
}
module "vpc" {
  source                = "./modules/vpc"
  vpc_cidr              = "10.0.0.0/16"
  public_subnet_1_cidr  = "10.0.1.0/24"
  public_subnet_2_cidr  = "10.0.2.0/24"
  private_subnet_1_cidr = "10.0.3.0/24"
  private_subnet_2_cidr = "10.0.4.0/24"
  az1                   = "us-east-1a"
  az2                   = "us-east-1b"
  allowed_ip            = "0.0.0.0/0"  # Substitua pelo seu IP
}

module "rds" {
  source       = "./modules/rds"
  db_username  = "contract_user" 
  db_password  = "supersecretpassword"
  db_host      = module.rds.rds_endpoint
  subnet_ids   = module.vpc.private_subnet_ids
  security_group_ids = [module.vpc.rds_security_group_id]
}

module "dynamodb" {
  source = "./modules/dynamodb"
}

module "sqs" {
  source                   = "./modules/sqs"
  contract_queue_arn       = module.sqs.contract_queue_arn
  contract_queue_url       = module.sqs.contract_queue_url
  process_sqs_postgres_arn = module.lambda.process_sqs_postgres_arn 

}

module "sns" {
  source          = "./modules/sns"
  contract_sqs_arn = module.sqs.contract_queue_arn
  contract_sqs_url = module.sqs.contract_queue_url
}

module "lambda_layer" {
  source = "./modules/lambda_layer"
}
resource "aws_security_group" "lambda_sg" {
  name        = "lambda-security-group"
  description = "Security group for Lambda functions"
  vpc_id      = module.vpc.vpc_id  # 🔥 Certifique-se de que o módulo VPC exporta `vpc_id`

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    security_groups = [module.vpc.rds_security_group_id]  # 🚀 Permite acesso ao RDS
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]  # 🚀 Permite saída para a internet
  }
}
module "lambda" {
  source                  = "./modules/lambda"
  dynamodb_table_name     = module.dynamodb.table_name
  sns_proposal_arn        = module.sns.sns_proposal_arn
  sqs_contract_queue_url  = module.sqs.contract_queue_url
  sqs_contract_queue_arn  = module.sqs.contract_queue_arn
  sqs_status_queue_url    = module.sqs.status_queue_url 
  sqs_status_queue_arn    = module.sqs.status_queue_arn 
  api_gateway_execution_arn = module.api_gateway.execution_arn
  db_host                = module.rds.db_host
  db_name                = "contracts"
  db_user                = "contract_user"
  db_password            = "supersecretpassword"
  private_subnet_ids       = module.vpc.private_subnet_ids
  lambda_security_group_id = aws_security_group.lambda_sg.id
  rds_security_group_id    = module.vpc.rds_security_group_id
}

module "api_gateway" {
  source              = "./modules/api_gateway"
  lambda_proposal_arn = module.lambda.store_proposal_arn  
  function_name       = module.lambda.store_proposal_function_name
}

module "monitoring" {
  source           = "./modules/monitoring"
  contract_dlq_name = module.sqs.contract_dlq_name
  sns_proposal_arn  = module.sns.sns_proposal_arn 
}
