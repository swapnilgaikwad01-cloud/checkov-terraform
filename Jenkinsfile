pipeline {
    agent any

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Terraform Validate') {
            steps {
                sh '''
                  docker run --rm \
                    -v "$(pwd):/workspace" \
                    -w /workspace \
                    hashicorp/terraform \
                    init -backend=false

                  docker run --rm \
                    -v "$(pwd):/workspace" \
                    -w /workspace \
                    hashicorp/terraform \
                    validate
                '''
            }
        }

        stage('Checkov Security Scan') {
            steps {
                sh '''
                    mkdir -p reports

                    docker run --rm \
                      -v "$(pwd):/app" \
                      -w /app \
                      bridgecrew/checkov \
                      -d . \
                      --framework terraform \
                      --output json \
                      --output-file-path reports/checkov-report.json \
                      --soft-fail
                '''
            }
            post {
                always {
                    archiveArtifacts artifacts: 'reports/*', fingerprint: true
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}