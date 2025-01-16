resource "aws_dynamodb_table" "proposals" {
  name         = "proposals_table"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "proposal_id"
    type = "S"
  }

  attribute {
    name = "created_at"
    type = "N"
  }

  hash_key  = "proposal_id"
  range_key = "created_at"

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
