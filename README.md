# AWS Lambda Deployment: S3 to RDS/Glue using Docker, Terraform & Jenkins CI/CD

## Overview
This project demonstrates an automated deployment pipeline for an AWS Lambda function that reads data from an S3 bucket and pushes it to an RDS database. If RDS is unavailable, the data is pushed to an AWS Glue Database. The deployment uses:

- **Docker** (Multistage build)
- **AWS ECR** (Elastic Container Registry)
- **AWS Lambda** (Function-as-a-Service)
- **AWS RDS / Glue** (Database storage options)
- **Jenkins** (CI/CD pipeline)
- **Terraform** (Infrastructure as Code)

## Architecture
1. Read data from an S3 bucket.
2. Attempt to push data to RDS.
3. If RDS is unavailable, store the data in AWS Glue Database.
4. Deploy the Lambda function using a multistage Docker image stored in AWS ECR.
5. Automate infrastructure provisioning and deployment with Terraform and Jenkins CI/CD.

---

## Prerequisites
- **AWS Account** with IAM permissions for Lambda, ECR, RDS, Glue, and S3
- **Terraform Installed** (`>=1.0.0`)
- **Docker Installed** (`>=20.10`)
- **Jenkins Installed** with AWS CLI & Terraform plugins
- **GitHub Repository** (for storing source code and Jenkins integration)

## Steps to Deploy

### 1. Clone the Repository
```sh
 git clone <repo-url>
 cd <repo-folder>
```

### 2. Create AWS Resources using Terraform
```sh
 cd terraform
 terraform init
 terraform apply -auto-approve
```
Terraform will create the following resources:
- **S3 Bucket** (Source data storage)
- **RDS Instance** (Primary database)
- **Glue Database** (Fallback option)
- **IAM Roles & Policies** (For Lambda execution)
- **ECR Repository** (For Docker image storage)

### 3. Build and Push the Docker Image to AWS ECR
```sh
 aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <aws-account-id>.dkr.ecr.<region>.amazonaws.com
 docker build -t s3-to-db-lambda .
 docker tag s3-to-db-lambda:latest <aws-account-id>.dkr.ecr.<region>.amazonaws.com/s3-to-db-lambda:latest
 docker push <aws-account-id>.dkr.ecr.<region>.amazonaws.com/s3-to-db-lambda:latest
```

### 4. Deploy Lambda Function
Terraform automatically deploys the Lambda function using the Docker image. If manual redeployment is needed:
```sh
 aws lambda update-function-code --function-name s3-to-db-lambda \
 --image-uri <aws-account-id>.dkr.ecr.<region>.amazonaws.com/s3-to-db-lambda:latest
```

### 5. Configure Jenkins Pipeline
- Add the repository to Jenkins.
- Set up a Jenkinsfile with stages for Terraform execution, Docker build, and Lambda deployment.
- Run the pipeline and verify deployment.

## Screenshots
**Include screenshots of:**
- **Jenkins pipeline execution**
- **Terraform resource creation**
- **AWS Console showing the created resources (S3, RDS, Glue, Lambda, ECR)**
- **Lambda function test results**

## Multistage Dockerfile
This project uses a **multistage Dockerfile** to keep the final image size minimal and efficient.

```dockerfile
# Stage 1: Build stage
FROM python:3.9 AS build
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Stage 2: Runtime stage
FROM python:3.9-slim
WORKDIR /app
COPY --from=build /usr/local/lib/python3.9/site-packages /usr/local/lib/python3.9/site-packages
COPY . .
CMD ["lambda_function.handler"]
```

## Conclusion
This project automates the deployment of a serverless Lambda function using a **multistage Docker image**, **Terraform for infrastructure provisioning**, and **Jenkins for CI/CD automation**. The function dynamically handles data ingestion from S3, stores it in RDS, and falls back to Glue if needed.

---
