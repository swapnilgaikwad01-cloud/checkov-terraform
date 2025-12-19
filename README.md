# Terraform Project Structure

This project contains reusable Terraform modules and environment-specific configurations.

## Structure

```
├── modules/
│   ├── s3/          # S3 bucket module
│   ├── lambda/      # Lambda function module
│   ├── dynamodb/    # DynamoDB table module
│   ├── vpc/         # VPC and networking module
│   └── iam/         # IAM roles and policies module
└── projects/
    ├── prod/        # Production environment
    └── non-prod/    # Non-production environment
```

## Usage

### Deploy to Production
```bash
cd projects/prod
terraform init
terraform plan
terraform apply
```

### Deploy to Non-Production
```bash
cd projects/non-prod
terraform init
terraform plan
terraform apply
```

## Modules

Each module contains:
- `main.tf` - Main resource definitions
- `variables.tf` - Input variables
- `outputs.tf` - Output values

## Environments

Each environment project uses the modules with environment-specific configurations and includes common tags for resource management.