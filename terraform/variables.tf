variable "aws_region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "us-east-1"  # Change this to your desired AWS region
}

variable "s3_bucket_name" {
  description = "The name of the S3 bucket for storing data"
  type        = string
  default     = "dvpatil-s3-bucket-7028t"
}

variable "db_instance_class" {
  description = "The RDS instance type"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "The name of the RDS database"
  type        = string
  default     = "mydatabase"
}

variable "db_username" {
  description = "The username for the RDS database"
  type        = string
  default     = "dvpatil"
}

variable "db_password" {
  description = "The password for the RDS database"
  type        = string
  sensitive   = true
  default     = "Dvpatil007"
}

variable "ecr_repo_name" {
  description = "The name of the ECR repository"
  type        = string
  default     = "my-docker-app"
}

variable "glue_database" {
  description = "The name of the AWS Glue database"
  type        = string
  default     = "mydatabase"
}

# Added VPC and Subnet variables
variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
  default     = "vpc-0039dac817184cb02"
}

variable "subnet_ids" {
  description = "List of subnet IDs"
  type        = list(string)
  default     = [
    "subnet-073450f04860f24e1",
    "subnet-074a2bac4375d5ffd",
    "subnet-01fabc919edbb45b0",
    "subnet-02aa9d2bf7d73a5d2"
  ]
}

