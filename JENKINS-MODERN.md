# Modern Jenkins Pipeline - Industry Best Practices

## Architecture Overview
This pipeline follows **industry-standard practices** used by major organizations:

- ✅ **Docker Agent Pattern** - Each stage runs in isolated containers
- ✅ **Zero Dependencies** - No local tool installation required
- ✅ **Stash/Unstash Pattern** - Efficient artifact sharing between stages
- ✅ **Parallel Execution** - Faster pipeline execution
- ✅ **Branch-based Conditions** - Smart execution based on branch
- ✅ **Comprehensive Reporting** - Multiple output formats

## Required Jenkins Plugins (Minimal)
```bash
# Core plugins (usually pre-installed)
- Pipeline Plugin
- Docker Pipeline Plugin
- Git Plugin
- JUnit Plugin

# Optional (for enhanced reporting)
- HTML Publisher Plugin
- Blue Ocean Plugin (for better UI)
```

## Pipeline Features

### 🔄 **Stage Isolation**
Each stage runs in its own Docker container:
- **Terraform Validation**: `hashicorp/terraform:1.6.0`
- **Security Scanning**: `bridgecrew/checkov:3.2.0`
- **Report Generation**: `bridgecrew/checkov:3.2.0`

### 📊 **Multi-Format Reports**
- **JUnit XML**: For Jenkins test results
- **JSON**: For detailed analysis
- **SARIF**: For security tools integration
- **CLI**: For console output

### 🚀 **Smart Execution**
- **Branch-based**: Terraform plan only on main/master
- **Parameter-based**: Manual trigger option
- **Parallel**: Prod/non-prod validation simultaneously

### 🔒 **Security First**
- **Soft-fail**: Pipeline continues even with security issues
- **Comprehensive scanning**: All Terraform files
- **Multiple frameworks**: Terraform, secrets, IaC

## Usage

### 1. Jenkins Job Configuration
```groovy
// Pipeline from SCM
Repository URL: <your-git-repo>
Branch: */main
Script Path: Jenkinsfile

// Build Parameters (optional)
Boolean Parameter: RUN_TERRAFORM_PLAN (default: false)
```

### 2. Automatic Triggers
```groovy
// Webhook trigger (recommended)
GitHub/GitLab webhook: http://jenkins-url/github-webhook/

// Poll SCM (fallback)
Schedule: H/5 * * * * (every 5 minutes)
```

### 3. Manual Execution
- **Quick Build**: Uses branch-based logic
- **Build with Parameters**: Override default behavior

## Industry Adoption

### **Why This Pattern?**
- **Netflix**: Uses Docker agents for microservices
- **Spotify**: Stash/unstash for artifact management
- **Airbnb**: Parallel execution for faster feedback
- **Uber**: Branch-based deployment strategies

### **Benefits**
- ✅ **Reproducible**: Same environment every time
- ✅ **Scalable**: Easy to add more agents
- ✅ **Maintainable**: No tool version conflicts
- ✅ **Portable**: Works on any Jenkins installation

## Troubleshooting

### Common Issues
1. **Docker not available**: Ensure Docker is running and Jenkins user has access
2. **Permission denied**: Add `-u root` to Docker args (already included)
3. **Network issues**: Check Docker registry access

### Debug Commands
```bash
# Test Docker access
docker run --rm hello-world

# Test specific images
docker run --rm hashicorp/terraform:1.6.0 version
docker run --rm bridgecrew/checkov:3.2.0 --version
```

## Migration from Legacy Pipelines
This pattern replaces:
- ❌ Local tool installations
- ❌ Complex PATH management
- ❌ Version conflicts
- ❌ Environment-specific issues

With:
- ✅ Container-based execution
- ✅ Declarative configuration
- ✅ Immutable environments
- ✅ Zero-dependency setup