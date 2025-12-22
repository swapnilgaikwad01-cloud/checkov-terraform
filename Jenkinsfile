pipeline {
    agent any

    environment {
        PATH = "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
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

        stage('Debug Environment') {
            steps {
                sh '''
                    whoami
                    echo "PATH=$PATH"
                    which docker || true
                    ls -la /usr/local/bin/docker || true
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
                            init -backend=false

                          docker run --rm \
                            -v "$(pwd):/workspace" \
                            -w /workspace/projects/prod \
                            hashicorp/terraform:${TERRAFORM_VERSION} \
                            validate
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
                            init -backend=false

                          docker run --rm \
                            -v "$(pwd):/workspace" \
                            -w /workspace/projects/non-prod \
                            hashicorp/terraform:${TERRAFORM_VERSION} \
                            validate
                        '''
                    }
                }
            }
        }


        stage('Checkov Security Scan') {
            steps {
                sh '''
                    mkdir -p reports

                    docker run --rm \
                      -v "$(pwd):/app" \
                      -w /app \
                      bridgecrew/checkov:${CHECKOV_VERSION} \
                      -d projects \
                      --framework terraform \
                      --output cli \
                      --output junitxml \
                      --output-file-path console,reports/checkov.xml \
                      --soft-fail
                '''
            }
            post {
                always {
                    junit testResults: 'reports/checkov.xml', allowEmptyResults: true
                    archiveArtifacts artifacts: 'reports/*', fingerprint: true
                }
            }
        }

        stage('Handle Checkov Result') {
            steps {
                script {
                    if (currentBuild.result == 'UNSTABLE') {
                        echo 'Checkov found issues (UNSTABLE). Continuing pipeline.'
                        currentBuild.result = 'SUCCESS'
                    }
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
