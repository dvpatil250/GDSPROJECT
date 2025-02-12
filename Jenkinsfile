pipeline {
    agent any

    environment {
        AWS_REGION = "us-east-1"
        AWS_ACCOUNT_ID = "491085402204"  
        ECR_REPO = "my-docker-app"
        IMAGE_TAG = "latest"
        DOCKER_DIR = "docker"  // Path where Dockerfile is stored
        TERRAFORM_DIR = "terraform"  // Path where Terraform files are stored
    }

    stages {
        stage('Checkout Code') {
            steps {
                git credentialsId: 'github-token', branch: 'GDS', url: 'https://github.com/dvpatil250/GDSPROJECT.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                cd $DOCKER_DIR
                docker build -t my-docker-app .
                '''
            }
        }
        
        stage('Authenticate to AWS ECR') {
            steps {
                withCredentials([aws(credentialsId: 'aws-credentials')]) {
                    sh '''
             aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 491085402204.dkr.ecr.us-east-1.amazonaws.com
                    '''
                }
            }
        }

        stage('Push to ECR') {
            steps {
                withCredentials([aws(credentialsId: 'aws-credentials')]) {
                    sh '''
                    aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 491085402204.dkr.ecr.us-east-1.amazonaws.com

                    docker tag my-docker-app:latest 491085402204.dkr.ecr.us-east-1.amazonaws.com/my-docker-app:latest
                    docker push 491085402204.dkr.ecr.us-east-1.amazonaws.com/my-docker-app:latest
                    '''
                }
            }
        }

        stage('Apply Terraform') {
            steps {
                withCredentials([aws(credentialsId: 'aws-credentials')]) {
                    sh '''
                    sudo apt-get update && sudo apt-get install -y terraform
                    cd $TERRAFORM_DIR
                    terraform init
                    terraform apply -auto-approve
                    '''
                }
            }
        }

        stage('Deploy Lambda') {
            steps {
                withCredentials([aws(credentialsId: 'aws-credentials')]) {
                    sh '''
                    aws lambda update-function-code --function-name s3_to_rds_lambda --image-uri 491085402204.dkr.ecr.us-east-1.amazonaws.com/my-docker-app:latest
                    '''
                }
            }
        }
    }
    
    post {
        success {
            echo 'Deployment Successful!'
        }
        failure {
            echo 'Deployment Failed. Check logs for details.'
        }
    }
}

