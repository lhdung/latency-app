# Network Latency Monitor

A simple solution for monitoring network latency between servers, featuring a FastAPI application and Infrastructure-as-Code deployment.

## 🎯 **Project Overview**

This project implements the requirements:
> *"Provision two virtual machines in a cloud environment and deploy a simple application on one of them that measures and exposes the network latency to the second server."*

**Key Features:**
- 🌐 **FastAPI Application**: Measures TCP connect latency between servers
- 🐳 **Docker Containerization**: Easy deployment and scaling
- 🏗️ **Infrastructure-as-Code**: Terraform for AWS deployment
- 📊 **Monitoring**: Prometheus metrics and health checks
- 🚀 **Simple Deployment**: Clean, straightforward setup

## 📁 **Project Structure**

```
├── app/
│   └── main.py                     # FastAPI application
├── terraform/
│   ├── main.tf                     # AWS infrastructure
│   ├── variables.tf                # Configuration variables
│   ├── outputs.tf                  # Deployment outputs
│   ├── user_data_monitor.sh        # Monitor server setup
│   ├── user_data_target.sh         # Target server setup
│   ├── terraform.tfvars.example    # Example configuration
│   └── environments/dev/           # Development environment
├── .github/workflows/              # CI/CD pipelines
├── Dockerfile                      # Container definition
├── requirements.txt                # Python dependencies
├── setup-local.sh                  # Setup helper script
├── deploy-local.sh                 # Simple deployment script
└── README.md                       # This file
```

## 🚀 **Quick Start**

### **Option 1: Simple Terraform Deployment**
```bash
# 1. Setup SSH keys and configuration
./setup-local.sh

# 2. Update terraform.tfvars with your SSH public key
nano terraform/environments/dev/terraform.tfvars

# 3. Deploy everything
./deploy-local.sh
```

### **Option 2: Docker Only (Local Testing)**
```bash
# Pull from Docker Hub
docker pull lhdung/latency-app:latest

# Run with target
docker run -p 8000:8000 \
  -e TARGET_HOST=google.com \
  -e TARGET_PORT=443 \
  lhdung/latency-app:latest

# Visit: http://localhost:8000/latency
```

### **Option 3: Manual Terraform Deployment**
```bash
# 1. Prerequisites
brew install terraform awscli
aws configure

# 2. Generate SSH key
ssh-keygen -t rsa -b 4096 -f ~/.ssh/latency-monitor

# 3. Configure variables
cp terraform/environments/dev/terraform.tfvars.example terraform/environments/dev/terraform.tfvars
# Edit with your SSH public key

# 4. Deploy
cd terraform/environments/dev
terraform init
terraform plan
terraform apply
```

## 📊 **API Endpoints**

Once deployed, the monitor server exposes these endpoints:

| Endpoint | Description | Example Response |
|----------|-------------|------------------|
| `/latency` | Current latency measurement | `{"latency_ms": 24.5, "target_host": "10.0.2.100", "timestamp": "..."}` |
| `/health` | Health check | `{"status": "healthy", "timestamp": "..."}` |
| `/metrics` | Prometheus metrics | Prometheus format metrics |
| `/docs` | API documentation | Interactive Swagger UI |

## 🔧 **Configuration**

### **Environment Variables**
- `TARGET_HOST`: IP/hostname of target server
- `TARGET_PORT`: Port to connect to (default: 80)
- `CHECK_INTERVAL_SECONDS`: How often to measure (default: 5)
- `CONNECT_TIMEOUT_SECONDS`: Connection timeout (default: 3)

### **Terraform Variables**
Edit `terraform/environments/dev/terraform.tfvars`:
```hcl
aws_region = "us-east-1"
public_key = "your-ssh-public-key-here"
ssh_allowed_cidr = ["your.ip.address/32"]  # Restrict SSH access
docker_image = "lhdung/latency-app:latest"
```

## 🧪 **Testing**

### **Local Development**
```bash
# Install dependencies
pip install -r requirements.txt

# Set environment variables
export TARGET_HOST=google.com
export TARGET_PORT=443

# Run locally
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

### **Docker Development**
```bash
# Build image
docker build -t latency-monitor .

# Run with target
docker run -p 8000:8000 \
  -e TARGET_HOST=1.1.1.1 \
  -e TARGET_PORT=53 \
  latency-monitor
```

## 🚀 **Deployment Options**

### **1. Simple AWS Deployment**
- ✅ Two EC2 instances (t3.micro - Free Tier eligible)
- ✅ Automatic target server configuration
- ✅ Security groups and networking
- ✅ Elastic IPs for stable access
- ✅ SSH access for troubleshooting

```bash
cd terraform/environments/dev
terraform init && terraform apply
```

### **2. Docker Compose (Local)**
```bash
# For local testing with mock target
docker-compose up
```

### **3. Manual Docker Run**
```bash
docker run -p 8000:8000 \
  -e TARGET_HOST=your-target-server \
  -e TARGET_PORT=80 \
  lhdung/latency-app:latest
```

## 📈 **Monitoring & Metrics**

### **Prometheus Metrics**
```
# HELP network_latency_ms Latest measured TCP connect latency
network_latency_ms{target_host="192.168.1.100",target_port="80"} 24.5

# HELP network_latency_success_total Number of successful measurements
network_latency_success_total{target_host="192.168.1.100",target_port="80"} 142

# HELP network_latency_failure_total Number of failed measurements  
network_latency_failure_total{target_host="192.168.1.100",target_port="80"} 3
```

### **Health Monitoring**
- Built-in health checks at `/health`
- Service status monitoring scripts on EC2 instances
- Automatic service restart on failure
- Comprehensive logging

## 💰 **Cost Estimation**

**AWS Deployment (Monthly):**
- 2 × t3.micro instances: ~$16 (Free Tier eligible)
- 2 × Elastic IPs: ~$7
- Data Transfer: Minimal (internal VPC)
- **Total**: ~$23/month (~$9 with Free Tier)

## 🔧 **Troubleshooting**

### **Common Issues**

**Service not responding:**
```bash
# Check service status
ssh -i ~/.ssh/latency-monitor ubuntu@MONITOR_IP
sudo systemctl status latency-monitor
```

**Wrong target being monitored:**
```bash
# Verify target configuration
curl http://MONITOR_IP:8000/latency | grep target_host
```

**Docker container issues:**
```bash
# Check container logs
ssh -i ~/.ssh/latency-monitor ubuntu@MONITOR_IP
sudo docker logs latency-monitor
```

**Update application:**
```bash
# SSH to monitor server and run update script
ssh -i ~/.ssh/latency-monitor ubuntu@MONITOR_IP
./update-app.sh
```

### **Manual Updates**
```bash
# SSH to monitor server
ssh -i ~/.ssh/latency-monitor ubuntu@MONITOR_IP

# Pull latest image and restart
./update-app.sh

# Check status
./check-service.sh
```

## 📝 **Required Variables**

| Variable | Description | Required |
|----------|-------------|----------|
| `public_key` | SSH public key for EC2 access | **Yes** |
| `aws_region` | AWS region for deployment | No |
| `instance_type` | EC2 instance type | No |
| `docker_image` | Docker image to deploy | No |

## 🔄 **CI/CD Pipeline**

GitHub Actions workflow automatically:
1. Builds Docker images on code changes
2. Pushes to Docker Hub
3. Runs security scans
4. Validates Terraform configurations

## 🚧 **Cleanup**

```bash
# Destroy infrastructure when done
cd terraform/environments/dev
terraform destroy

# Clean up local files
rm -rf .terraform
rm terraform.tfstate*
```

## 📄 **License**

This project is licensed under the MIT License.

## 🤝 **Contributing**

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

---

**Built with ❤️ for simple, reliable network latency monitoring**