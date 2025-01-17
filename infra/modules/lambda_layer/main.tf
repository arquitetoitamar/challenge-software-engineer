resource "aws_lambda_layer_version" "psycopg2_layer" {
  filename         = "${path.module}/psycopg2-layer.zip"
  layer_name       = "psycopg2"
  compatible_runtimes = ["python3.9"]
}
