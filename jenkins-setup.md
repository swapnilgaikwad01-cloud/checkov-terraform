# Jenkins Setup for Checkov Integration
#This is to setup Jenkins
## Prerequisites
- Jenkins installed locally on Mac
- Docker installed and running
- Git repository initialized

## Jenkins Configuration

### 1. Install Required Plugins
- Docker Pipeline Plugin
- JUnit Plugin
- HTML Publisher Plugin
- Pipeline Plugin

### 2. Create New Pipeline Job
1. Open Jenkins dashboard
2. Click "New Item"
3. Enter job name: `terraform-checkov-pipeline`
4. Select "Pipeline"
5. Click "OK"

### 3. Configure Pipeline
In the Pipeline section:
- Definition: Pipeline script from SCM
- SCM: Git
- Repository URL: `https://github.com/yourusername/terraform-checkov.git` (or your Git URL)
- Credentials: Add if private repository
- Branch Specifier: `*/main` (or `*/master`)
- Script Path: `Jenkinsfile`

### 4. Add Build Parameters (Optional)
- Boolean Parameter: `RUN_TERRAFORM_PLAN` (default: false)

## Local Testing

### Run Checkov Standalone
```bash
./scripts/run-checkov.sh
```

### Run with Docker Compose
```bash
docker-compose run checkov
```

### Manual Docker Run
```bash
docker run --rm -v $(pwd):/app -w /app bridgecrew/checkov:latest checkov -d . --framework terraform
```

## Pipeline Features
- ✅ Code checkout from Git repository
- ✅ Docker-based tool installation
- ✅ Terraform validation
- ✅ Checkov security scanning
- ✅ Multiple report formats (XML, JSON, SARIF)
- ✅ JUnit test result publishing
- ✅ Artifact archiving
- ✅ Parallel Terraform planning

## Alternative Approaches

### 1. Agent-based (Traditional)
- Install tools directly on Jenkins agent
- Faster execution, no Docker overhead
- Requires manual tool management

### 2. Kubernetes-based
- Use Jenkins with Kubernetes plugin
- Dynamic agent provisioning
- Better for scalability

### 3. GitHub Actions (if using GitHub)
- Cloud-native CI/CD
- Pre-built actions available
- No local Jenkins maintenance
