pipeline {
    agent any
    
    environment {
        CHECKOV_VERSION = '3.2.0'
        TERRAFORM_VERSION = '1.6.0'
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out code from Git repository'
                 checkout scm
            }
        }
        
        stage('Setup Tools') {
            steps {
                sh '''
                    docker run --rm python:3.11-slim pip install checkov==${CHECKOV_VERSION}
                    docker run --rm bridgecrew/checkov:${CHECKOV_VERSION} --version
                '''
            }
        }
        
        stage('Terraform Validation') {
            steps {
                sh '''
                    docker run --rm -v $(pwd):/workspace -w /workspace \
                        hashicorp/terraform:${TERRAFORM_VERSION} \
                        sh -c "cd projects/prod && terraform init -backend=false && terraform validate"
                    
                    docker run --rm -v $(pwd):/workspace -w /workspace \
                        hashicorp/terraform:${TERRAFORM_VERSION} \
                        sh -c "cd projects/non-prod && terraform init -backend=false && terraform validate"
                '''
            }
        }
        
        stage('Checkov Security Scan') {
            steps {
                sh '''
                    docker run --rm -v $(pwd):/app -w /app \
                        bridgecrew/checkov:${CHECKOV_VERSION} \
                        checkov -d . \
                            --framework terraform \
                            --output cli \
                            --output junitxml \
                            --output-file-path console,checkov-report.xml \
                            --soft-fail
                '''
            }
            post {
                always {
                    archiveArtifacts artifacts: 'checkov-report.xml', fingerprint: true
                    publishTestResults testResultsPattern: 'checkov-report.xml'
                }
            }
        }
        
        stage('Generate HTML Report') {
            steps {
                sh '''
                    docker run --rm -v $(pwd):/app -w /app \
                        bridgecrew/checkov:${CHECKOV_VERSION} \
                        checkov -d . \
                            --framework terraform \
                            --output json \
                            --output-file-path checkov-detailed-report.json \
                            --soft-fail
                '''
            }
            post {
                always {
                    archiveArtifacts artifacts: 'checkov-detailed-report.json', fingerprint: true
                }
            }
        }
        
        stage('Terraform Plan') {
            when {
                expression { params.RUN_TERRAFORM_PLAN == true }
            }
            parallel {
                stage('Plan - Production') {
                    steps {
                        sh '''
                            docker run --rm -v $(pwd):/workspace -w /workspace \
                                hashicorp/terraform:${TERRAFORM_VERSION} \
                                sh -c "cd projects/prod && terraform init -backend=false && terraform plan -out=prod.tfplan"
                        '''
                    }
                }
                stage('Plan - Non-Production') {
                    steps {
                        sh '''
                            docker run --rm -v $(pwd):/workspace -w /workspace \
                                hashicorp/terraform:${TERRAFORM_VERSION} \
                                sh -c "cd projects/non-prod && terraform init -backend=false && terraform plan -out=nonprod.tfplan"
                        '''
                    }
                }
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed. Check the logs for details.'
        }
    }
}