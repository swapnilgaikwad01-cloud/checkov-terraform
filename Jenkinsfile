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

        stage('Checkov Scan') {
            steps {
                script {
                    docker.image('bridgecrew/checkov:latest').inside('--entrypoint=""') {
                        sh """
                          mkdir -p reports
                          cd ${TF_DIR}

                          checkov -d . \
                            --framework terraform \
                            --output cli \
                            --output json \
                            --output-file-path console,reports/checkov.json \
                            --soft-fail | tee reports/checkov.txt
                        """
                    }
                }
            }
        }

        stage('Post or Update PR Comment') {
            when {
                expression { env.CHANGE_ID != null }
            }
            steps {
                withCredentials([
                    string(credentialsId: 'github-checks-token', variable: 'GITHUB_TOKEN')
                ]) {
                    sh '''
set -e

OWNER=$(echo "$GIT_URL" | sed -E 's#.*/([^/]+)/([^/.]+)(\\.git)?#\\1#')
REPO=$(echo "$GIT_URL" | sed -E 's#.*/([^/]+)/([^/.]+)(\\.git)?#\\2#')
PR=$CHANGE_ID

CHECKOV_SUMMARY=$(grep -E "Passed checks:|Failed checks:|Skipped checks:" reports/checkov.txt || true)

COMMENT=$(cat <<EOF
### 🔐 Checkov Security Scan Results

**Repository:** $REPO
**PR:** #$PR
**Commit:** $GIT_COMMIT

**Checkov Summary**
\`\`\`
$CHECKOV_SUMMARY
\`\`\`

📎 Full JSON report is available in Jenkins build artifacts.
EOF
)

EXISTING_COMMENT_ID=$(curl -s \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  https://api.github.com/repos/$OWNER/$REPO/issues/$PR/comments \
  | jq -r '.[] | select(.body | contains("### 🔐 Checkov Security Scan Results")) | .id' | head -n1)

if [ -n "$EXISTING_COMMENT_ID" ]; then
    curl -s -X PATCH \
      -H "Authorization: Bearer $GITHUB_TOKEN" \
      -H "Accept: application/vnd.github+json" \
      https://api.github.com/repos/$OWNER/$REPO/issues/comments/$EXISTING_COMMENT_ID \
      -d "$(jq -n --arg body "$COMMENT" '{body: $body}')"
else
    curl -s -X POST \
      -H "Authorization: Bearer $GITHUB_TOKEN" \
      -H "Accept: application/vnd.github+json" \
      https://api.github.com/repos/$OWNER/$REPO/issues/$PR/comments \
      -d "$(jq -n --arg body "$COMMENT" '{body: $body}')"
fi
'''
                }
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: 'reports/*', fingerprint: true
        }
        success {
            echo "✅ Terraform validation and Checkov scan completed"
        }
    }
}