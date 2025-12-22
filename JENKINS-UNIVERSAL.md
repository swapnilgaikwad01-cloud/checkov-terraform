# Universal Jenkins Pipeline - Zero Plugin Dependencies

## Overview
This pipeline works with **any Jenkins installation** without requiring additional plugins. It uses standard `docker run` commands that work on any system with Docker.

## ✅ What's Included
- **Terraform Validation**: Syntax and configuration validation
- **Checkov Security Scan**: Infrastructure security analysis
- **Report Generation**: XML and JSON reports
- **Terraform Planning**: Optional infrastructure planning
- **Artifact Archiving**: Build artifacts storage

## 🔧 Requirements (Minimal)
1. **Jenkins** (any version with Pipeline support)
2. **Docker** (accessible to Jenkins user)
3. **Git** (for source code management)

## 📋 Jenkins Job Setup

### 1. Create Pipeline Job
```
1. Jenkins Dashboard → New Item
2. Enter name: "terraform-checkov-pipeline"
3. Select: Pipeline
4. Click OK
```

### 2. Configure Pipeline
```
Pipeline Section:
- Definition: Pipeline script from SCM
- SCM: Git
- Repository URL: https://github.com/swapnilgaikwad01-cloud/checkov-terraform.git
- Branch: */main
- Script Path: Jenkinsfile
```

### 3. Add Build Parameter (Optional)
```
General Section:
☑ This project is parameterized
- Add Boolean Parameter
- Name: RUN_TERRAFORM_PLAN
- Default Value: false
- Description: Run Terraform plan stage
```

## 🚀 Pipeline Stages

### Stage 1: Checkout
- Pulls source code from Git
- Lists files for verification

### Stage 2: Terraform Validation
- Validates both prod and non-prod configurations
- Uses official Terraform Docker image
- No backend initialization (safe)

### Stage 3: Checkov Security Scan
- Scans all Terraform files
- Generates JUnit XML report
- Uses soft-fail (won't break pipeline)

### Stage 4: Generate Reports
- Creates detailed JSON report
- Archives for later analysis

### Stage 5: Terraform Plan (Conditional)
- Runs only on main/master branch OR when parameter is true
- Parallel execution for prod/non-prod
- Generates plan files

## 🔍 Key Features

### Error Handling
- `|| true` prevents pipeline failure
- Conditional file archiving
- Graceful error handling

### Branch Logic
- Terraform plan only on main branches
- Parameter override available
- Smart conditional execution

### Docker Integration
- Uses official images
- Volume mounting for file access
- Isolated execution environments

## 📊 Reports Generated
- `checkov-report.xml` - JUnit format for Jenkins
- `checkov-report.json` - Detailed findings
- `prod.tfplan` - Production plan (if enabled)
- `nonprod.tfplan` - Non-production plan (if enabled)

## 🐛 Troubleshooting

### Common Issues
1. **Docker not found**
   ```bash
   # Check Docker access
   docker --version
   sudo usermod -aG docker jenkins
   sudo systemctl restart jenkins
   ```

2. **Permission denied**
   ```bash
   # Fix Docker permissions
   sudo chmod 666 /var/run/docker.sock
   ```

3. **Image pull failures**
   ```bash
   # Pre-pull images
   docker pull hashicorp/terraform:1.6.0
   docker pull bridgecrew/checkov:3.2.0
   ```

## 🎯 Usage Examples

### Manual Build
1. Go to job → Build Now
2. Check Console Output
3. View archived artifacts

### Parameterized Build
1. Go to job → Build with Parameters
2. Set RUN_TERRAFORM_PLAN = true
3. Click Build

### Webhook Trigger
```bash
# GitHub webhook URL
http://your-jenkins-url:8080/github-webhook/
```

This pipeline is **production-ready** and follows industry standards while maintaining simplicity and compatibility.