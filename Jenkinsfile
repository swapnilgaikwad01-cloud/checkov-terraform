pipeline {
    agent any

    environment {
        TF_DIR = "."
        CHECKOV_OUTPUT_DIR = "checkov-results"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
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

        stage('Checkov Security Scan') {
            steps {
                script {
                    docker.image('bridgecrew/checkov:latest').inside('--entrypoint=""') {
                        sh """
                          mkdir -p ${CHECKOV_OUTPUT_DIR}

                          checkov \
                            -d ${TF_DIR} \
                            --config-file .checkov.yaml \
                            --output json \
                            --output junitxml \
                            --output-file-path ${CHECKOV_OUTPUT_DIR} \
                            || true
                        """
                    }
                }
            }
        }
    }

    post {
        always {
            script {
                if (fileExists("${CHECKOV_OUTPUT_DIR}/junitxml.xml")) {
                    junit allowEmptyResults: true, testResults: "${CHECKOV_OUTPUT_DIR}/junitxml.xml"
                }
            }

            archiveArtifacts artifacts: "${CHECKOV_OUTPUT_DIR}/*", fingerprint: true
        }

        unstable {
            echo "⚠️ Checkov found security issues (build marked UNSTABLE)"
        }

        success {
            echo "✅ Terraform validation and Checkov scan completed successfully"
        }

        failure {
            echo "❌ Terraform validation failed"
        }
    }
}