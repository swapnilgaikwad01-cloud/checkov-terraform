pipeline {
    agent none
    
    environment {
        CHECKOV_VERSION = '3.2.0'
        TERRAFORM_VERSION = '1.6.0'
    }
    
    stages {
        stage('Checkout') {
            agent any
            steps {
                checkout scm
                stash includes: '**/*', name: 'source-code'
            }
        }
        
        stage('Terraform Validation') {
            agent {
                docker {
                    image "hashicorp/terraform:${env.TERRAFORM_VERSION}"
                    args '-u root'
                }
            }
            steps {
                unstash 'source-code'
                sh '''
                    cd projects/prod
                    terraform init -backend=false
                    terraform validate
                    
                    cd ../non-prod
                    terraform init -backend=false
                    terraform validate
                '''
            }
        }
        
        stage('Checkov Security Scan') {
            agent {
                docker {
                    image "bridgecrew/checkov:${env.CHECKOV_VERSION}"
                    args '-u root'
                }
            }
            steps {
                unstash 'source-code'
                sh '''
                    checkov -d . \
                        --framework terraform \
                        --output cli \
                        --output junitxml \
                        --output-file-path console,checkov-report.xml \
                        --soft-fail
                '''
                stash includes: 'checkov-report.xml', name: 'checkov-results', allowEmpty: true
            }
        }
        
        stage('Generate Reports') {
            agent {
                docker {
                    image "bridgecrew/checkov:${env.CHECKOV_VERSION}"
                    args '-u root'
                }
            }
            steps {
                unstash 'source-code'
                sh '''
                    checkov -d . \
                        --framework terraform \
                        --output json \
                        --output sarif \
                        --output-file-path checkov-report.json,checkov-sarif.json \
                        --soft-fail
                '''
                stash includes: '*.json', name: 'reports', allowEmpty: true
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
                    agent {
                        docker {
                            image "hashicorp/terraform:${env.TERRAFORM_VERSION}"
                            args '-u root'
                        }
                    }
                    steps {
                        unstash 'source-code'
                        sh '''
                            cd projects/prod
                            terraform init -backend=false
                            terraform plan -out=prod.tfplan
                        '''
                        stash includes: 'projects/prod/prod.tfplan', name: 'prod-plan', allowEmpty: true
                    }
                }
                stage('Plan - Non-Production') {
                    agent {
                        docker {
                            image "hashicorp/terraform:${env.TERRAFORM_VERSION}"
                            args '-u root'
                        }
                    }
                    steps {
                        unstash 'source-code'
                        sh '''
                            cd projects/non-prod
                            terraform init -backend=false
                            terraform plan -out=nonprod.tfplan
                        '''
                        stash includes: 'projects/non-prod/nonprod.tfplan', name: 'nonprod-plan', allowEmpty: true
                    }
                }
            }
        }
        
        stage('Publish Results') {
            agent any
            steps {
                unstash 'checkov-results'
                unstash 'reports'
                
                // Archive artifacts
                archiveArtifacts artifacts: '*.xml,*.json', fingerprint: true, allowEmptyArchive: true
                
                // Publish test results
                publishTestResults testResultsPattern: 'checkov-report.xml', allowEmptyResults: true
                
                // Publish HTML reports if plugin available
                script {
                    try {
                        publishHTML([
                            allowMissing: true,
                            alwaysLinkToLastBuild: true,
                            keepAll: true,
                            reportDir: '.',
                            reportFiles: 'checkov-report.json',
                            reportName: 'Checkov Security Report'
                        ])
                    } catch (Exception e) {
                        echo "HTML Publisher plugin not available: ${e.message}"
                    }
                }
            }
        }
    }
    
    post {
        always {
            node('') {
                cleanWs()
            }
        }
        success {
            echo '✅ Pipeline completed successfully!'
        }
        failure {
            echo '❌ Pipeline failed. Check the logs for details.'
        }
        unstable {
            echo '⚠️ Pipeline completed with warnings.'
        }
    }
}