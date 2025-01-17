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
  allowed_ip            = "192.168.1.1/32"  # Substitua pelo seu IP
}

module "rds" {
  source       = "./modules/rds"
  db_username  = "contract_user"  # Correção aplicada
  db_password  = "supersecretpassword"
  db_host      = module.rds.rds_endpoint
  subnet_ids   = module.vpc.private_subnet_ids
  security_group_ids = [module.vpc.rds_security_group_id]
}

module "dynamodb" {
  source = "./modules/dynamodb"
}

module "sqs" {
  source = "./modules/sqs"
  contract_queue_arn = module.sqs.contract_queue_arn
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

module "lambda" {
  source = "./modules/lambda"

  dynamodb_table_name    = module.dynamodb.table_name
  sns_proposal_arn       = module.sns.sns_proposal_arn
  sqs_contract_queue_url = module.sqs.contract_queue_url
  sqs_contract_queue_arn = module.sqs.contract_queue_arn
  api_gateway_execution_arn = module.api_gateway.execution_arn
  db_host               = module.rds.db_host
  db_name               = "contracts"
  db_user               = "contract_user"
  db_password           = "supersecretpassword"
}


module "api_gateway" {
  source              = "./modules/api_gateway"
  lambda_proposal_arn = module.lambda.store_proposal_arn  
  function_name       = "store-proposal"
}

module "monitoring" {
  source           = "./modules/monitoring"
  contract_dlq_name = module.sqs.contract_dlq_name
  sns_proposal_arn  = module.sns.sns_proposal_arn 
}
