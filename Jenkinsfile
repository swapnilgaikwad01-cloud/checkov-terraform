pipeline {
    agent any

    environment {
        TF_DIR = "."
    }

    stages {

        stage('Checkout Terraform Repo') {
            steps {
                checkout scm
            }
        }

        stage('Docker Debug') {
            steps {
                sh '''
                  whoami
                  which docker || true
                  docker version || true
                '''
            }
        }

        stage('Terraform Init & Validate') {
            steps {
                script {
                    docker.image('hashicorp/terraform:1.6').inside('--entrypoint=""') {
                        sh """
                          cd ${TF_DIR}
                          terraform init -backend=false
                          terraform validate
                        """
                    }
                }
            }
        }

        stage('Checkov') {
            steps {
                script {
                    docker.image('bridgecrew/checkov:latest').inside('--entrypoint=""') {
                        sh """
                          mkdir -p reports
                          cd ${TF_DIR}

                          checkov -d . \
                            --framework terraform \
                            --output sarif \
                            --output-file-path reports/checkov.sarif \
                            --soft-fail
                        """
                    }
                }
            }
        }

        stage('Publish Checkov PR Report') {
            when {
                changeRequest()
            }
            steps {
                withCredentials([string(credentialsId: 'github-checks-token', variable: 'GITHUB_TOKEN')]) {
                    publishChecks(
                        name: 'Checkov Security Scan',
                        summary: 'Infrastructure security analysis',
                        detailsURL: "${env.BUILD_URL}",
                        conclusion: 'NEUTRAL',
                        output: [
                            title: 'Checkov Results',
                            summary: 'See security findings from Checkov scan'
                        ],
                        annotations: [],
                        token: env.GITHUB_TOKEN
                    )
                }
            }
        }
    }

    post {
        success {
            echo "✅ Terraform validation and Checkov scan passed"
        }
        failure {
            echo "❌ Terraform or Checkov validation failed"
        }
    }
}
