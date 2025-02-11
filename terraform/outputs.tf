## outputs.tf
output "s3_bucket" {
  value = aws_s3_bucket.data_bucket.bucket
}

output "rds_instance" {
  value = aws_db_instance.rds_instance.endpoint
}

output "ecr_repo" {
  value = aws_ecr_repository.app_repo.repository_url
}
output "lambda_function" {
  value = aws_lambda_function.s3_to_rds_lambda.function_name
}
