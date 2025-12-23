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
                          cd ${TF_DIR}
                          checkov -d .
                        """
                    }
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