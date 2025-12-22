# Updated Jenkins Pipeline Configuration

## Git Repository Setup

### 1. Initialize and Push to Git
```bash
cd /Users/swapnil.gaikwad01/poc/checkov
git init
git add .
git commit -m "Initial Terraform project with Jenkins pipeline"

# If using GitHub/GitLab/Bitbucket
git remote add origin <your-git-repository-url>
git push -u origin main
```

### 2. Jenkins Pipeline Configuration

#### For Remote Git Repository:
- Repository URL: `https://github.com/yourusername/terraform-checkov.git`
- Credentials: Add GitHub/GitLab credentials if private
- Branch: `*/main`

#### For Local Git Repository:
- Repository URL: `file:///Users/swapnil.gaikwad01/poc/checkov`
- Ensure system property is set: `hudson.plugins.git.GitSCM.ALLOW_LOCAL_CHECKOUT=true`
- Branch: `*/main`

### 3. Pipeline Triggers (Optional)

Add to Jenkins job configuration:
- **Poll SCM**: `H/5 * * * *` (check every 5 minutes)
- **GitHub hook trigger**: For automatic builds on push
- **Build periodically**: `H 2 * * *` (daily at 2 AM)

### 4. Webhook Setup (For Remote Repositories)

#### GitHub:
1. Go to repository Settings → Webhooks
2. Add webhook: `http://your-jenkins-url:8080/github-webhook/`
3. Content type: `application/json`
4. Events: `Just the push event`

#### GitLab:
1. Go to repository Settings → Webhooks
2. Add webhook: `http://your-jenkins-url:8080/project/your-job-name`
3. Trigger: `Push events`

## Updated Pipeline Features
- ✅ Git-based source control
- ✅ Automatic triggering on code changes
- ✅ Branch-specific builds
- ✅ Commit information in build logs