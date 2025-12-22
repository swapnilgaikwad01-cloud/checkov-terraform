pipeline {
    agent any

    environment {
        CHECKOV_VERSION = '3.2.0'
        TERRAFORM_VERSION = '1.6.0'
        REPORTS_DIR = 'reports'
    }

    stages {

        stage('Preflight Checks') {
            steps {
                sh '''
                    echo "🔍 Checking Docker availability"
                    docker version
                '''
            }
        }

        stage('Checkout') {
            steps {
                checkout scm
                sh 'ls -la'
            }
        }

        stage('Terraform Validate') {
            parallel {

                stage('Validate - Prod') {
                    steps {
                        sh '''
                        docker run --rm \
                          -v "$(pwd):/workspace" \
                          -w /workspace/projects/prod \
                          hashicorp/terraform:${TERRAFORM_VERSION} \
                          sh -c "terraform init -backend=false && terraform validate"
                        '''
                    }
                }

                stage('Validate - NonProd') {
                    steps {
                        sh '''
                        docker run --rm \
                          -v "$(pwd):/workspace" \
                          -w /workspace/projects/non-prod \
                          hashicorp/terraform:${TERRAFORM_VERSION} \
                          sh -c "terraform init -backend=false && terraform validate"
                        '''
                    }
                }
            }
        }

        stage('Checkov Scan') {
            steps {
                sh '''
                    mkdir -p ${REPORTS_DIR}

                    docker run --rm \
                      -v "$(pwd):/app" \
                      -w /app \
                      bridgecrew/checkov:${CHECKOV_VERSION} \
                      checkov \
                        -d projects \
                        --framework terraform \
                        --output cli \
                        --output junitxml \
                        --output-file-path console,${REPORTS_DIR}/checkov.xml \
                        --soft-fail
                '''
            }
            post {
                always {
                    junit testResults: 'reports/checkov.xml', allowEmptyResults: true
                }
            }
        }

        stage('Terraform Plan') {
            when {
                branch 'main'
            }
            parallel {

                stage('Plan - Prod') {
                    steps {
                        sh '''
                        docker run --rm \
                          -v "$(pwd):/workspace" \
                          -w /workspace/projects/prod \
                          hashicorp/terraform:${TERRAFORM_VERSION} \
                          sh -c "terraform init -backend=false && terraform plan"
                        '''
                    }
                }

                stage('Plan - NonProd') {
                    steps {
                        sh '''
                        docker run --rm \
                          -v "$(pwd):/workspace" \
                          -w /workspace/projects/non-prod \
                          hashicorp/terraform:${TERRAFORM_VERSION} \
                          sh -c "terraform init -backend=false && terraform plan"
                        '''
                    }
                }
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: 'reports/*', fingerprint: true
            cleanWs()
        }
    }
}
