# ==============================
# AWS S3 Bucket
# ==============================
resource "aws_s3_bucket" "data_bucket" {
  bucket = var.s3_bucket_name

  tags = {
    Name = "My S3 Data Bucket"
  }
}

resource "aws_s3_bucket_ownership_controls" "data_bucket_ownership" {
  bucket = aws_s3_bucket.data_bucket.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# ==============================
# RDS Security Group
# ==============================
resource "aws_security_group" "rds_sg" {
  name        = "rds-security-group"
  description = "Allow Lambda to access RDS"
  vpc_id      = var.vpc_id # Replace with your VPC variable

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Change this to specific IPs for security
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ==============================
# RDS Instance with Subnet Group
# ==============================
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group"
  subnet_ids = var.subnet_ids  # Use a variable for subnets

  tags = {
    Name = "RDS Subnet Group"
  }
}

resource "aws_db_instance" "rds_instance" {
  allocated_storage    = 20
  engine              = "postgres"
  instance_class      = var.db_instance_class
  username           = var.db_username
  password           = var.db_password
  publicly_accessible = false  # Set to false for security
  skip_final_snapshot = true
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]  # Attach Security Group
}

# ==============================
# AWS ECR Repository
# ==============================
resource "aws_ecr_repository" "app_repo" {
  name = var.ecr_repo_name
}

# ==============================
# IAM Role and Policy for Lambda
# ==============================
resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_policy" "lambda_policy" {
  name        = "lambda_policy"
  description = "IAM policy for Lambda execution"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:s3:::${var.s3_bucket_name}/*"
      },
      {
        Action = [
          "rds:DescribeDBInstances",
          "rds-db:connect"
        ]
        Effect   = "Allow"
        Resource = aws_db_instance.rds_instance.arn
      },
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:AttachNetworkInterface",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeNetworkInterfaces"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# ==============================
# AWS Lambda Function
# ==============================
resource "aws_lambda_function" "s3_to_rds_lambda" {
  function_name = "s3_to_rds_lambda"
  image_uri     = "${aws_ecr_repository.app_repo.repository_url}:latest"
  package_type  = "Image"
  role          = aws_iam_role.lambda_exec.arn

  timeout       = 300  # Increase timeout to 2 minutes
  memory_size   = 1024  # Increase memory for better performance

  vpc_config {
    subnet_ids         = var.subnet_ids  # Ensure Lambda runs inside the same VPC as RDS
    security_group_ids = [aws_security_group.rds_sg.id]
  }

  environment {
    variables = {
      S3_BUCKET     = var.s3_bucket_name
      DB_HOST       = aws_db_instance.rds_instance.endpoint
      DB_NAME       = var.db_name
      DB_USER       = var.db_username
      DB_PASSWORD   = var.db_password
      GLUE_DATABASE = var.glue_database
    }
  }

  depends_on = [aws_ecr_repository.app_repo]
}

# ==============================
# S3 Event Trigger for Lambda
# ==============================
resource "aws_s3_bucket_notification" "s3_trigger_lambda" {
  bucket = aws_s3_bucket.data_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_to_rds_lambda.arn
    events              = ["s3:ObjectCreated:*"]
  }
}

# Grant S3 permission to invoke Lambda
resource "aws_lambda_permission" "allow_s3_invoke" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_to_rds_lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.data_bucket.arn
}
