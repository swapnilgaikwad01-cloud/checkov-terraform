pipeline {
    agent any
    
    environment {
        CHECKOV_VERSION = '3.2.0'
        TERRAFORM_VERSION = '1.6.0'
        PATH = "/usr/local/bin:/opt/homebrew/bin:${env.PATH}"
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
                    # Check if Docker is available
                    which docker || echo "Docker not found in PATH"
                    
                    # Install Checkov using pip3 (fallback approach)
                    if command -v pip3 >/dev/null 2>&1; then
                        pip3 install --user checkov==${CHECKOV_VERSION}
                        export PATH="$HOME/.local/bin:$PATH"
                        checkov --version
                    else
                        echo "Neither Docker nor pip3 available. Installing pip3..."
                        curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
                        python3 get-pip.py --user
                        export PATH="$HOME/.local/bin:$PATH"
                        pip3 install --user checkov==${CHECKOV_VERSION}
                        checkov --version
                    fi
                '''
            }
        }
        
        stage('Terraform Validation') {
            steps {
                sh '''
                    # Check if terraform is available locally
                    if command -v terraform >/dev/null 2>&1; then
                        echo "Using local Terraform installation"
                        cd projects/prod && terraform init -backend=false && terraform validate
                        cd ../non-prod && terraform init -backend=false && terraform validate
                    else
                        echo "Terraform not found locally. Downloading..."
                        curl -fsSL https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_darwin_amd64.zip -o terraform.zip
                        unzip terraform.zip
                        chmod +x terraform
                        ./terraform version
                        
                        cd projects/prod && ../../terraform init -backend=false && ../../terraform validate
                        cd ../non-prod && ../../terraform init -backend=false && ../../terraform validate
                    fi
                '''
            }
        }
        
        stage('Checkov Security Scan') {
            steps {
                sh '''
                    export PATH="$HOME/.local/bin:$PATH"
                    
                    # Run Checkov scan on all Terraform files
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
                    archiveArtifacts artifacts: 'checkov-report.xml', fingerprint: true, allowEmptyArchive: true
                    junit testResults: 'checkov-report.xml', allowEmptyResults: true
                }
            }
        }
        
        stage('Generate HTML Report') {
            steps {
                sh '''
                    export PATH="$HOME/.local/bin:$PATH"
                    
                    # Generate detailed JSON report
                    checkov -d . \
                        --framework terraform \
                        --output json \
                        --output-file-path checkov-detailed-report.json \
                        --soft-fail
                '''
            }
            post {
                always {
                    archiveArtifacts artifacts: 'checkov-detailed-report.json', fingerprint: true, allowEmptyArchive: true
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
                            if command -v terraform >/dev/null 2>&1; then
                                cd projects/prod && terraform init -backend=false && terraform plan -out=prod.tfplan
                            else
                                cd projects/prod && ../../terraform init -backend=false && ../../terraform plan -out=prod.tfplan
                            fi
                        '''
                    }
                }
                stage('Plan - Non-Production') {
                    steps {
                        sh '''
                            if command -v terraform >/dev/null 2>&1; then
                                cd projects/non-prod && terraform init -backend=false && terraform plan -out=nonprod.tfplan
                            else
                                cd projects/non-prod && ../../terraform init -backend=false && ../../terraform plan -out=nonprod.tfplan
                            fi
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