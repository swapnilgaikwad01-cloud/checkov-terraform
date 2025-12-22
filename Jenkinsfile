pipeline {
    agent any
    
    environment {
        CHECKOV_VERSION = '3.2.0'
        TERRAFORM_VERSION = '1.6.0'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                sh 'ls -la'
            }
        }
        
        stage('Terraform Validation') {
            steps {
                sh '''
                    docker run --rm -v "$(pwd):/workspace" -w /workspace \
                        hashicorp/terraform:${TERRAFORM_VERSION} \
                        sh -c "cd projects/prod && terraform init -backend=false && terraform validate"
                    
                    docker run --rm -v "$(pwd):/workspace" -w /workspace \
                        hashicorp/terraform:${TERRAFORM_VERSION} \
                        sh -c "cd projects/non-prod && terraform init -backend=false && terraform validate"
                '''
            }
        }
        
        stage('Checkov Security Scan') {
            steps {
                sh '''
                    docker run --rm -v "$(pwd):/app" -w /app \
                        bridgecrew/checkov:${CHECKOV_VERSION} \
                        checkov -d . \
                            --framework terraform \
                            --output cli \
                            --output junitxml \
                            --output-file-path console,checkov-report.xml \
                            --soft-fail || true
                '''
            }
            post {
                always {
                    script {
                        if (fileExists('checkov-report.xml')) {
                            archiveArtifacts artifacts: 'checkov-report.xml', fingerprint: true
                            junit testResults: 'checkov-report.xml', allowEmptyResults: true
                        }
                    }
                }
            }
        }
        
        stage('Generate Reports') {
            steps {
                sh '''
                    docker run --rm -v "$(pwd):/app" -w /app \
                        bridgecrew/checkov:${CHECKOV_VERSION} \
                        checkov -d . \
                            --framework terraform \
                            --output json \
                            --output-file-path checkov-report.json \
                            --soft-fail || true
                '''
            }
            post {
                always {
                    script {
                        if (fileExists('checkov-report.json')) {
                            archiveArtifacts artifacts: 'checkov-report.json', fingerprint: true
                        }
                    }
                }
            }
        }
        
        stage('Terraform Plan') {
            when {
                anyOf {
                    branch 'main'
                    branch 'master'
                    expression { return params.RUN_TERRAFORM_PLAN == true }
                }
            }
            parallel {
                stage('Plan - Production') {
                    steps {
                        sh '''
                            docker run --rm -v "$(pwd):/workspace" -w /workspace \
                                hashicorp/terraform:${TERRAFORM_VERSION} \
                                sh -c "cd projects/prod && terraform init -backend=false && terraform plan -out=prod.tfplan" || true
                        '''
                    }
                }
                stage('Plan - Non-Production') {
                    steps {
                        sh '''
                            docker run --rm -v "$(pwd):/workspace" -w /workspace \
                                hashicorp/terraform:${TERRAFORM_VERSION} \
                                sh -c "cd projects/non-prod && terraform init -backend=false && terraform plan -out=nonprod.tfplan" || true
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
            echo '✅ Pipeline completed successfully!'
        }
        failure {
            echo '❌ Pipeline failed. Check the logs for details.'
        }
    }
}