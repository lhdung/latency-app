# Terraform Infrastructure - Network Latency Monitor

This directory contains the complete Terraform infrastructure code for the Network Latency Monitor application, restructured into a production-ready modular architecture.

## 🏗️ Architecture Overview

```
terraform/
├── environments/           # Environment-specific configurations
│   ├── dev/               # Development environment
│   ├── staging/           # Staging environment (template)
│   └── prod/              # Production environment
├── modules/               # Reusable Terraform modules
│   ├── networking/        # VPC, subnets, routing
│   ├── security/          # Security groups, key pairs
│   ├── compute/           # EC2 instances, EIPs
│   └── latency-monitor/   # Complete solution module
├── scripts/               # Automation scripts
├── shared/                # Shared configurations
└── README.md              # This file
```

## 🚀 Quick Start

### 1. Setup Backend Infrastructure

First, create the S3 bucket and DynamoDB table for Terraform state management:

```bash
cd terraform/scripts
chmod +x setup-backend.sh
./setup-backend.sh
```

This creates:
- S3 bucket for Terraform state (encrypted with KMS)
- DynamoDB table for state locking
- KMS key for encryption
- Backend configuration files for each environment

### 2. Deploy Development Environment

```bash
cd terraform/scripts
./deploy-environment.sh dev plan     # Review changes
./deploy-environment.sh dev apply    # Deploy infrastructure
```

### 3. Deploy Production Environment

```bash
cd terraform/scripts
./deploy-environment.sh prod plan    # Review changes
./deploy-environment.sh prod apply   # Deploy with approval
```

## 📁 Module Structure

### Core Modules

#### `modules/networking/`
- **Purpose**: VPC, subnets, internet gateway, routing
- **Features**: 
  - Multi-AZ deployment
  - Optional NAT Gateway for private subnets
  - VPC Flow Logs for security monitoring
  - Configurable CIDR blocks

#### `modules/security/`
- **Purpose**: Security groups, key pairs
- **Features**:
  - Separate security groups for monitor and target
  - Configurable CIDR restrictions
  - Internal communication rules
  - Optional monitoring tools access

#### `modules/compute/`
- **Purpose**: EC2 instances, Elastic IPs
- **Features**:
  - Auto-configured with user data scripts
  - CloudWatch monitoring and alarms
  - EBS encryption
  - Instance metadata service v2 (IMDSv2)

#### `modules/latency-monitor/`
- **Purpose**: Complete solution combining all modules
- **Features**:
  - End-to-end infrastructure deployment
  - Environment-specific configurations
  - Comprehensive outputs for integration

## 🌍 Environment Configurations

### Development (`environments/dev/`)
- **Purpose**: Development and testing
- **Features**:
  - Cost-optimized settings (t3.micro instances)
  - Relaxed security for development
  - No NAT Gateway or detailed monitoring
  - Additional dev-specific resources

### Production (`environments/prod/`)
- **Purpose**: Production workloads
- **Features**:
  - Production-grade instances (t3.small+)
  - Enhanced security and compliance
  - VPC Flow Logs and detailed monitoring
  - CloudWatch alarms and SNS notifications
  - KMS encryption for all data
  - Strict CIDR restrictions

## 🔧 Configuration

### Required Variables

Each environment requires these essential variables in `terraform.tfvars`:

```hcl
# SSH Key (generate with: ssh-keygen -t rsa -b 4096 -f ~/.ssh/{env}-latency-monitor)
public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC..."

# Network access (restrict for production)
ssh_allowed_cidr = ["YOUR.IP.ADDRESS/32"]

# Application settings
docker_image = "lhdung/latency-app:latest"
instance_type = "t3.micro"  # or t3.small for production
```

### Environment-Specific Settings

| Setting | Development | Production |
|---------|-------------|------------|
| Instance Type | `t3.micro` | `t3.small+` |
| VPC CIDR | `10.0.0.0/16` | `10.100.0.0/16` |
| SSH Access | Open (dev only) | Restricted |
| Monitoring | Basic | Detailed |
| Encryption | Basic | Full KMS |
| Flow Logs | Disabled | Enabled |
| Alarms | Disabled | Enabled |

## 🔒 Security Features

### Development Security
- ✅ Basic encryption
- ✅ Security groups
- ⚠️ Open SSH (configurable)
- ⚠️ No flow logs (cost optimization)

### Production Security
- ✅ KMS encryption for all data
- ✅ VPC Flow Logs for network monitoring
- ✅ Restricted SSH access (validation enforced)
- ✅ CloudWatch detailed monitoring
- ✅ SNS alerts for failures
- ✅ IAM roles with least privilege
- ✅ IMDSv2 enforcement
- ✅ S3 bucket security policies

## 📊 Monitoring & Alerting

### CloudWatch Metrics
- EC2 instance health checks
- Application health endpoints
- Custom latency metrics via Prometheus

### Alerting (Production)
- Instance status check failures
- Application health check failures
- SNS notifications to operations team

### Logs
- VPC Flow Logs (production)
- Application logs via CloudWatch
- S3 lifecycle policies for log retention

## 🔄 CI/CD Integration

GitHub Actions workflow (`.github/workflows/terraform-cicd.yml`) provides:

### Validation Pipeline
- Terraform format checking
- Module validation
- Security scanning (Checkov, TFSec)
- Linting (TFLint)

### Deployment Pipeline
- **Development**: Auto-deploy on `develop` branch
- **Production**: Manual approval required on `main` branch
- Plan artifacts for review
- Automated testing after deployment

### Required GitHub Secrets
```
AWS_ACCESS_KEY_ID          # Development AWS credentials
AWS_SECRET_ACCESS_KEY      # Development AWS credentials
AWS_ACCESS_KEY_ID_PROD     # Production AWS credentials
AWS_SECRET_ACCESS_KEY_PROD # Production AWS credentials
```

## 🚀 Deployment Commands

### Manual Deployment
```bash
# Initialize and plan
cd terraform/environments/dev
terraform init -backend-config=backend-config.hcl
terraform plan -var-file=terraform.tfvars

# Apply changes
terraform apply -var-file=terraform.tfvars

# Destroy (when needed)
terraform destroy -var-file=terraform.tfvars
```

### Automated Deployment
```bash
# Using the deployment script
cd terraform/scripts
./deploy-environment.sh dev apply
./deploy-environment.sh prod apply
```

## 📋 Prerequisites

### Tools Required
- Terraform >= 1.0
- AWS CLI configured
- Bash shell (for automation scripts)

### AWS Permissions
Your AWS credentials need permissions for:
- EC2 (instances, security groups, key pairs)
- VPC (networking resources)
- S3 (state storage)
- DynamoDB (state locking)
- KMS (encryption keys)
- CloudWatch (monitoring, logs)
- SNS (notifications)
- IAM (roles and policies)

## 🔍 Troubleshooting

### Common Issues

**Backend not found:**
```bash
# Run the backend setup script first
cd terraform/scripts
./setup-backend.sh
```

**Permission denied:**
```bash
# Ensure scripts are executable
chmod +x terraform/scripts/*.sh
```

**State locked:**
```bash
# Force unlock if needed (use carefully)
terraform force-unlock LOCK_ID
```

### Validation Commands
```bash
# Validate all modules
cd terraform
terraform fmt -check -recursive
terraform validate

# Test specific environment
cd environments/dev
terraform plan -var-file=terraform.tfvars
```

## 🎯 Migration from Legacy

To migrate from the old monolithic structure:

1. **Backup existing state** (if any)
2. **Run backend setup** to create new infrastructure
3. **Import existing resources** (if needed)
4. **Deploy new modular structure**
5. **Verify functionality**
6. **Remove legacy files**

## 📚 Additional Resources

- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/)
- [AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Module Development](https://www.terraform.io/docs/modules/index.html)

## 🤝 Contributing

1. Make changes in feature branches
2. Test in development environment
3. Submit pull request with plan output
4. Review and approve for production deployment

---

This modular architecture provides a production-ready, scalable, and maintainable infrastructure foundation for the Network Latency Monitor application.