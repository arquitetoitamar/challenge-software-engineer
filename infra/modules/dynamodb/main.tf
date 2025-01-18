resource "aws_dynamodb_table" "proposals" {
  name         = "proposals_table"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "proposal_id"
    type = "S"
  }

  hash_key = "proposal_id"  # 🔥 `proposal_id` é a única chave primária agora

  ttl {
    attribute_name = "expiration_time"
    enabled        = false
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = {
    Environment = "Production"
  }
}
