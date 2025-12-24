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
                            --output json \
                            --output-file-path reports/checkov.json \
                            --soft-fail

                          checkov -d . \
                            --framework terraform \
                            --quiet \
                            | grep -E "Passed checks:|Failed checks:|Skipped checks:" > reports/checkov-summary.txt || true
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

CHECKOV_SUMMARY=$(cat reports/checkov-summary.txt || true)
CHECKOV_JSON=$(cat reports/checkov.json | sed 's/^/    /')

COMMENT=$(cat <<EOF
### 🔍 Checkov Terraform Security Scan

**Repository:** $REPO
**PR:** #$PR
**Commit:** $GIT_COMMIT

**Summary**
$CHECKOV_SUMMARY

**Checkov JSON**
$CHECKOV_JSON

_Jenkins Build:_ $BUILD_URL
EOF
)

EXISTING_COMMENT_ID=$(curl -s \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  https://api.github.com/repos/$OWNER/$REPO/issues/$PR/comments \
  | jq -r '.[] | select(.body | contains("### 🔍 Checkov Terraform Security Scan")) | .id' | head -n1)

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
        success {
            echo "✅ Terraform validation and Checkov scan completed"
        }
        failure {
            echo "❌ Terraform or Checkov validation failed"
        }
    }
}