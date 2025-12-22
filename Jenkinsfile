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
                git branch: 'main',
                url: 'https://github.com/swapnilgaikwad01-cloud/checkov-terraform.git'
            }
        }
        
        stage('Setup Tools') {
            steps {
                script {
                    docker.image("python:3.11-slim").inside {
                        sh '''
                            pip install checkov==${CHECKOV_VERSION}
                            checkov --version
                        '''
                    }
                }
            }
        }
        
        stage('Terraform Validation') {
            steps {
                script {
                    docker.image("hashicorp/terraform:${TERRAFORM_VERSION}").inside {
                        dir('projects/prod') {
                            sh '''
                                terraform init -backend=false
                                terraform validate
                            '''
                        }
                        dir('projects/non-prod') {
                            sh '''
                                terraform init -backend=false
                                terraform validate
                            '''
                        }
                    }
                }
            }
        }
        
        stage('Checkov Security Scan') {
            steps {
                script {
                    docker.image("python:3.11-slim").inside {
                        sh '''
                            pip install checkov==${CHECKOV_VERSION}
                            
                            # Run Checkov scan on all Terraform files
                            checkov -d . \
                                --framework terraform \
                                --output cli \
                                --output junitxml \
                                --output-file-path console,checkov-report.xml \
                                --soft-fail
                        '''
                    }
                }
            }
            post {
                always {
                    // Archive the Checkov report
                    archiveArtifacts artifacts: 'checkov-report.xml', fingerprint: true
                    
                    // Publish JUnit test results
                    publishTestResults testResultsPattern: 'checkov-report.xml'
                }
            }
        }
        
        stage('Generate HTML Report') {
            steps {
                script {
                    docker.image("python:3.11-slim").inside {
                        sh '''
                            pip install checkov==${CHECKOV_VERSION}
                            
                            # Generate detailed HTML report
                            checkov -d . \
                                --framework terraform \
                                --output json \
                                --output-file-path checkov-detailed-report.json \
                                --soft-fail
                        '''
                    }
                }
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
                        script {
                            docker.image("hashicorp/terraform:${TERRAFORM_VERSION}").inside {
                                dir('projects/prod') {
                                    sh '''
                                        terraform init -backend=false
                                        terraform plan -out=prod.tfplan
                                    '''
                                }
                            }
                        }
                    }
                }
                stage('Plan - Non-Production') {
                    steps {
                        script {
                            docker.image("hashicorp/terraform:${TERRAFORM_VERSION}").inside {
                                dir('projects/non-prod') {
                                    sh '''
                                        terraform init -backend=false
                                        terraform plan -out=nonprod.tfplan
                                    '''
                                }
                            }
                        }
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